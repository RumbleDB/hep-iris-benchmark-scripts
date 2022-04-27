#include "ROOT/RDataFrame.hxx"
#include "TCanvas.h"

void benchmark2(const std::vector<std::string> input = {"root://eospublic.cern.ch//eos/root-eos/benchmark/Run2012B_SingleMu.root"},
                const bool multithreading = true) {
    if (multithreading) ROOT::EnableImplicitMT();

    ROOT::RDataFrame df("Events", input);
    auto h = df.Histo1D({"", ";Jet p_{T} (GeV);N_{Events}", 100, 15, 60}, "Jet_pt");

    TCanvas c;
    h->Draw();
    c.SaveAs("benchmark2.root");
}
