.PHONY: benchmark notes

JULIA = julia
JULIA_CMD = $(JULIA) --startup-file=no
JULIA_PLOT = $(JULIA_CMD) --project=plots

JULIA_PROJECT ?= $(PWD)/environments/v1.6
export JULIA_PROJECT

JULIA_PKG_PRECOMPILE_AUTO = 0
export JULIA_PKG_PRECOMPILE_AUTO

GKSwstype ?= nul
export GKSwstype

notes: notes.pdf

notes.pdf: notes.ipynb
	jupyter nbconvert --to=pdf $<

notes.ipynb: notes/notes.jl
	$(JULIA) -e 'using Literate; Literate.notebook("notes/notes.jl")'

data/done/instantiate: $(JULIA_PROJECT)/Manifest.toml
	@mkdir -pv $$(dirname $@)
	$(JULIA_CMD) -e 'using Pkg; Pkg.instantiate()'
	touch $@

benchmark: data/done/benchmark
data/done/benchmark: data/done/instantiate
	@mkdir -pv $$(dirname $@)
	$(JULIA_CMD) -e 'using ThreadsAPIBenchmarks; run_benchmarks()'
	touch $@
