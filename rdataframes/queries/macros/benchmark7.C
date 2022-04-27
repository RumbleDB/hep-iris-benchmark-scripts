#include "ROOT/RDataFrame.hxx"
#include "ROOT/RVec.hxx"
#include "TCanvas.h"

ROOT::RVec<int> get_jet_lepton_isolation(const ROOT::RVec<float> &jet_eta,
                                         const ROOT::RVec<float> &jet_phi,
                                         const ROOT::RVec<float> &lepton_eta,
                                         const ROOT::RVec<float> &lepton_phi) {
    ROOT::RVec<int> jet_mask(jet_eta.size(), 1);
    if (jet_eta.size() == 0 || lepton_eta.size() == 0) {
        return jet_mask;
    }

    const auto jet_lepton_indices = ROOT::VecOps::Combinations(jet_eta, lepton_eta);
    for (auto i = 0; i < jet_lepton_indices[0].size(); ++i) {
        const auto jet_idx = jet_lepton_indices[0][i];
        const auto lepton_idx = jet_lepton_indices[1][i];
        const auto deltaR = ROOT::VecOps::DeltaR(jet_eta[jet_idx], lepton_eta[lepton_idx], jet_phi[jet_idx], lepton_phi[lepton_idx]);
        if (deltaR < 0.4) {
            jet_mask[jet_idx] = 0;
        }
    }
    return jet_mask;
}


void benchmark7(const std::vector<std::string> input = {"root://eospublic.cern.ch//eos/root-eos/benchmark/Run2012B_SingleMu.root"},
                const bool multithreading = true) {
    if (multithreading) ROOT::EnableImplicitMT();

    ROOT::RDataFrame df("Events", input);
    auto h = df.Define("Lepton_pt", "Concatenate(Electron_pt, Muon_pt)")
               .Define("Lepton_eta", "Concatenate(Electron_eta, Muon_eta)")
               .Define("Lepton_phi", "Concatenate(Electron_phi, Muon_phi)")
               .Define("goodLepton", "Lepton_pt > 10")
               .Define("goodLepton_eta", "Lepton_eta[goodLepton]")
               .Define("goodLepton_phi", "Lepton_phi[goodLepton]")
               .Define("goodJet", "Jet_pt > 30")
               .Define("goodJet_pt", "Jet_pt[goodJet]")
               .Define("goodJet_eta", "Jet_eta[goodJet]")
               .Define("goodJet_phi", "Jet_phi[goodJet]")
               .Define("goodJet_leptonIsolation", get_jet_lepton_isolation, {"goodJet_eta", "goodJet_phi", "goodLepton_eta", "goodLepton_phi"})
               .Define("goodIsolatedJet_sumPt", "Sum(goodJet_pt[goodJet_leptonIsolation])")
               .Histo1D({"", ";Jet p_{T} sum (GeV);N_{Events}", 100, 15, 200}, "goodIsolatedJet_sumPt");

    TCanvas c;
    h->Draw();
    c.SaveAs("benchmark7.root");
}
