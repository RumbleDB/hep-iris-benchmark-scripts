#include "Math/Vector4D.h"
#include "ROOT/RDataFrame.hxx"
#include "ROOT/RVec.hxx"
#include "TCanvas.h"

ROOT::RVec<ROOT::Math::PtEtaPhiMVector> make_p4(const ROOT::RVec<float> &pt,
                                                const ROOT::RVec<float> &eta,
                                                const ROOT::RVec<float> &phi,
                                                const ROOT::RVec<float> &mass) {
    return ROOT::VecOps::Map(pt, eta, phi, mass, [](const float pt, const float eta, const float phi, const float mass){ return ROOT::Math::PtEtaPhiMVector(pt, eta, phi, mass); });
}

ROOT::RVec<float> get_dimuon_mass(const ROOT::RVec<ROOT::Math::PtEtaPhiMVector> &muon_p4,
                                  const ROOT::RVec<int> &muon_charge) {
    ROOT::RVec<float> dimuon_mass;
    const auto dimuon_indices = ROOT::VecOps::Combinations(muon_p4, 2);
    for (auto i = 0; i < dimuon_indices[0].size(); ++i) {
        const auto muon_idx0 = dimuon_indices[0][i];
        const auto muon_idx1 = dimuon_indices[1][i];
        if (muon_charge[muon_idx0] != muon_charge[muon_idx1]) {
            dimuon_mass.push_back((muon_p4[muon_idx0] + muon_p4[muon_idx1]).mass());
        }
    }
    return dimuon_mass;
}

void benchmark5(const std::vector<std::string> input = {"root://eospublic.cern.ch//eos/root-eos/benchmark/Run2012B_SingleMu.root"},
                const bool multithreading = true) {
    if (multithreading) ROOT::EnableImplicitMT();

    ROOT::RDataFrame df("Events", input);
    auto h = df.Filter("nMuon >= 2")
               .Define("Muon_p4", make_p4, {"Muon_pt", "Muon_eta", "Muon_phi", "Muon_mass"})
               .Define("Dimuon_mass", get_dimuon_mass, {"Muon_p4", "Muon_charge"})
               .Filter("Any(60 < Dimuon_mass && Dimuon_mass < 120)")
               .Histo1D({"", ";MET (GeV);N_{Events}", 100, 0, 2000}, "MET_pt");

    TCanvas c;
    h->Draw();
    c.SaveAs("benchmark5.root");
}
