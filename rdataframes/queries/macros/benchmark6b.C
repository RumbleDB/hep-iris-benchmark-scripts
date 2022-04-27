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

ROOT::RVec<ROOT::Math::PtEtaPhiMVector> get_trijet_p4(const ROOT::RVec<ROOT::Math::PtEtaPhiMVector> &jet_p4,
                                                      const ROOT::RVec<ROOT::RVec<std::size_t> > &trijet_indices) {
    ROOT::RVec<ROOT::Math::PtEtaPhiMVector> trijet_p4;
    for (auto i = 0; i < trijet_indices[0].size(); ++i) {
        const auto jet_idx0 = trijet_indices[0][i];
        const auto jet_idx1 = trijet_indices[1][i];
        const auto jet_idx2 = trijet_indices[2][i];
        trijet_p4.emplace_back(jet_p4[jet_idx0] + jet_p4[jet_idx1] + jet_p4[jet_idx2]);
    }
    return trijet_p4;
}

ROOT::RVec<float> get_mass(const ROOT::RVec<ROOT::Math::PtEtaPhiMVector> &p4) {
    return ROOT::VecOps::Map(p4, [](const ROOT::Math::PtEtaPhiMVector &p4){ return p4.mass(); });
}

void benchmark6b(const std::vector<std::string> input = {"root://eospublic.cern.ch//eos/root-eos/benchmark/Run2012B_SingleMu.root"},
                const bool multithreading = true) {
    if (multithreading) ROOT::EnableImplicitMT();

    ROOT::RDataFrame df("Events", input);
    auto df2 = df.Filter("nJet >= 3")
                 .Define("Jet_p4", make_p4, {"Jet_pt", "Jet_eta", "Jet_phi", "Jet_mass"})
                 .Define("Trijet_indices", "Combinations(Jet_p4, 3)")
                 .Define("Trijet_p4", get_trijet_p4, {"Jet_p4", "Trijet_indices"})
                 .Define("Trijet_mass", get_mass, {"Trijet_p4"})
                 .Define("Best_trijet_idx", "ArgMin(abs(Trijet_mass - 172.5))")
                 .Define("Best_trijet_leading_btag", "Max(Take(Jet_btag, {Trijet_indices[0][Best_trijet_idx], Trijet_indices[1][Best_trijet_idx], Trijet_indices[2][Best_trijet_idx]}))");
    auto h2 = df2.Histo1D({"", ";Trijet leading b-tag;N_{Events}", 100, 0, 1}, "Best_trijet_leading_btag");

    TCanvas c;
    h2->Draw();
    c.SaveAs("benchmark6b.root");
}
