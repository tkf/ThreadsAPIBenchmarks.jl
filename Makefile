.PHONY: benchmark notes

JULIA = julia
JULIA_CMD = $(JULIA) --startup-file=no

JULIA_PROJECT ?= $(PWD)/environments/v1.6
export JULIA_PROJECT

JULIA_PKG_PRECOMPILE_AUTO = 0
export JULIA_PKG_PRECOMPILE_AUTO

GKSwstype ?= nul
export GKSwstype

DATA_TAG = $(shell $(JULIA_CMD) --compile=min -e 'print(VERSION)')

notes_files = \
data/$(DATA_TAG)/notes.ipynb \
data/$(DATA_TAG)/notes.pdf

notes: $(notes_files)

$(notes_files): data/$(DATA_TAG)/%: %
	cp --no-target-directory $< $@

notes.pdf: notes.ipynb
	jupyter nbconvert --to=pdf $<

notes.ipynb: notes/notes.jl data/done/$(DATA_TAG)/benchmark
	$(JULIA) -e 'using Literate; Literate.notebook("notes/notes.jl")'

data/done/$(DATA_TAG)/instantiate: $(JULIA_PROJECT)/Manifest.toml
	@mkdir -pv $$(dirname $@)
	$(JULIA_CMD) -e 'using Pkg; Pkg.instantiate()'
	touch $@

benchmark: data/done/$(DATA_TAG)/benchmark
data/done/$(DATA_TAG)/benchmark: data/done/$(DATA_TAG)/instantiate
	@mkdir -pv $$(dirname $@)
	$(JULIA_CMD) -e 'using ThreadsAPIBenchmarks; run_benchmarks()'
	touch $@
