#include "ROOT/RDataFrame.hxx"
#include "TCanvas.h"

void benchmark4(const std::vector<std::string> input = {"root://eospublic.cern.ch//eos/root-eos/benchmark/Run2012B_SingleMu.root"},
                const bool multithreading = true) {
    if (multithreading) ROOT::EnableImplicitMT();

    ROOT::RDataFrame df("Events", input);
    auto h = df.Filter("Sum(Jet_pt > 40) >= 2")
               .Histo1D({"", ";MET (GeV);N_{Events}", 100, 0, 2000}, "MET_pt");

    TCanvas c;
    h->Draw();
    c.SaveAs("benchmark4.root");
}
