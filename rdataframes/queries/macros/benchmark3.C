#include "ROOT/RDataFrame.hxx"
#include "TCanvas.h"

void benchmark3(const std::vector<std::string> input = {"root://eospublic.cern.ch//eos/root-eos/benchmark/Run2012B_SingleMu.root"},
                const bool multithreading = true) {
    if (multithreading) ROOT::EnableImplicitMT();

    ROOT::RDataFrame df("Events", input);
    auto h = df.Define("goodJet_pt", "Jet_pt[abs(Jet_eta) < 1]")
               .Histo1D({"", ";Jet p_{T} (GeV);N_{Events}", 100, 15, 60}, "goodJet_pt");

    TCanvas c;
    h->Draw();
    c.SaveAs("benchmark3.root");
}
