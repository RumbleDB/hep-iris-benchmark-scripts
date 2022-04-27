#include "Math/Vector4D.h"
#include "ROOT/RDataFrame.hxx"
#include "ROOT/RVec.hxx"
#include "TCanvas.h"

ROOT::RVec<ROOT::RVec<std::size_t> > get_dilepton_indices(const ROOT::RVec<int> &flavor,
                                                          const ROOT::RVec<int> &charge) {
    ROOT::RVec<ROOT::RVec<std::size_t> > dilepton_indices(2);
    const auto indices = ROOT::VecOps::Combinations(flavor, 2);
    for (auto i = 0; i < indices[0].size(); ++i) {
        const auto idx0 = indices[0][i];
        const auto idx1 = indices[1][i];
        if (flavor[idx0] == flavor[idx1] && charge[idx0] != charge[idx1]) {
            dilepton_indices[0].push_back(idx0);
            dilepton_indices[1].push_back(idx1);
        }
    }
    return dilepton_indices;
}

ROOT::RVec<ROOT::Math::PtEtaPhiMVector> make_p4(const ROOT::RVec<float> &pt,
                                                const ROOT::RVec<float> &eta,
                                                const ROOT::RVec<float> &phi,
                                                const ROOT::RVec<float> &mass) {
    return ROOT::VecOps::Map(pt, eta, phi, mass, [](const float pt, const float eta, const float phi, const float mass){ return ROOT::Math::PtEtaPhiMVector(pt, eta, phi, mass); });
}

ROOT::RVec<float> get_dilepton_mass(const ROOT::RVec<ROOT::Math::PtEtaPhiMVector> &lepton_p4,
                                    const ROOT::RVec<ROOT::RVec<std::size_t> > &dilepton_indices) {
    ROOT::RVec<float> dilepton_mass;
    for (auto i = 0; i < dilepton_indices[0].size(); ++i) {
        const auto lepton_idx0 = dilepton_indices[0][i];
        const auto lepton_idx1 = dilepton_indices[1][i];
        dilepton_mass.push_back((lepton_p4[lepton_idx0] + lepton_p4[lepton_idx1]).mass());
    }
    return dilepton_mass;
}

void benchmark8(const std::vector<std::string> input = {"root://eospublic.cern.ch//eos/root-eos/benchmark/Run2012B_SingleMu.root"},
                const bool multithreading = true) {
    if (multithreading) ROOT::EnableImplicitMT();

    ROOT::RDataFrame df("Events", input);
    auto h = df.Filter("nElectron + nMuon >= 3")
               .Define("Lepton_flavor", "Concatenate(ROOT::RVec<int>(nElectron, 0), ROOT::RVec<int>(nMuon, 1))")
               .Define("Lepton_charge", "Concatenate(Electron_charge, Muon_charge)")
               .Define("Dilepton_indices", get_dilepton_indices, {"Lepton_flavor", "Lepton_charge"})
               .Filter("Dilepton_indices[0].size() > 0")
               .Define("Lepton_pt", "Concatenate(Electron_pt, Muon_pt)")
               .Define("Lepton_eta", "Concatenate(Electron_eta, Muon_eta)")
               .Define("Lepton_phi", "Concatenate(Electron_phi, Muon_phi)")
               .Define("Lepton_mass", "Concatenate(Electron_mass, Muon_mass)")
               .Define("Lepton_p4", make_p4, {"Lepton_pt", "Lepton_eta", "Lepton_phi", "Lepton_mass"})
               .Define("Dilepton_mass", get_dilepton_mass, {"Lepton_p4", "Dilepton_indices"})
               .Define("Best_dilepton_idx", "ArgMin(abs(Dilepton_mass - 91.2))")
               .Define("LeadingLepton_indices", "Reverse(Argsort(Lepton_pt))")
               .Define("LeadingOtherLepton_idx", "LeadingLepton_indices[LeadingLepton_indices != Dilepton_indices[0][Best_dilepton_idx] && LeadingLepton_indices != Dilepton_indices[1][Best_dilepton_idx]][0]")
               .Define("METAndLeadingOtherLepton_mt", "sqrt(2 * Lepton_pt[LeadingOtherLepton_idx] * MET_pt * (1 - cos(ROOT::VecOps::DeltaPhi(Lepton_phi[LeadingOtherLepton_idx], MET_phi))))")
               .Histo1D({"", ";m_{T} (GeV);N_{Events}", 100, 15, 250}, "METAndLeadingOtherLepton_mt");

    TCanvas c;
    h->Draw();
    c.SaveAs("benchmark8.root");
}
