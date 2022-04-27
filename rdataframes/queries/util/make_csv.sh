#!/bin/bash

for root_file in "$@"
do
	root -b -l >"$(basename -s .root "$root_file").csv" <<EOF
	TFile f("$root_file");
	auto *h = static_cast<TH1 *>(c1->FindObject(""));
	auto *x_axis = h->GetXaxis();
	std::cout << "lower_edge,upper_edge,content" << std::endl;
	for (auto i = 1; i <= x_axis->GetNbins(); ++i) {
		const auto lower_edge = x_axis->GetBinLowEdge(i);
		const auto upper_edge = x_axis->GetBinUpEdge(i);
		const auto content = h->GetBinContent(i);
		std::cout << lower_edge << "," << upper_edge << "," << content << std::endl;
	}
EOF
done
