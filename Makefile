#!/usr/bin/make -f

# Central Makefile for Vivado projects and docs
# ---------------------------------------------
# Usage:
#   Docs (from repo root):
#     make docs                    # build HTML (default)
#     make docs html | make docs clean | make docs clean html
#     Uses docs/.venv and docs/pyproject.toml (pip install -e docs).
#
#   Vivado (from repo root, all equivalent):
#     make crs_corr32 project      # convenience: <config> <action>
#     make CONFIG=crs_corr32 project
#     make crs_corr32              # shorthand: default action is 'bitstream'
#
#   From inside a project directory (e.g. xilinx_projects/chfpga_crs_corr32):
#     ../make project              # CONFIG inferred from directory name
#     ../make bitstream
#     ../make clean
#
# Actions:  project | bitstream | clean  (Vivado);  docs [targets...]  (Sphinx)
#
# Dependency discovery:
#   vivado -mode batch -notrace -source create_project.tcl -tclargs --list_files_only
#   Requires tcl/create_generic_project.tcl to support --list_files_only.

VIVADO  := vivado -mode batch -notrace
ACTIONS := project bitstream clean
SHELL   := /bin/bash
MAKEFLAGS += --no-print-directory

_G1 := $(word 1,$(MAKECMDGOALS))
_G2 := $(word 2,$(MAKECMDGOALS))

# Configs = directories xilinx_projects/chfpga_* that have create_project.tcl
VALID_CONFIGS := $(sort $(foreach d,$(wildcard xilinx_projects/chfpga_*),$(if $(wildcard $(d)/create_project.tcl),$(patsubst chfpga_%,%,$(notdir $(d))),)))

.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo "Usage:"
	@echo "  "
	@echo "    make <config> project      # Create Vivado project for <config>"
	@echo "    make <config> bitstream    # Build bitstream for config <config>"
	@echo "    make <config> clean         # Clean <config> project and bitstream"
	@echo "    make all                    # build bitstream for every <config>"
	@echo "    make docs [clean][html]     # Build the documentation"
	@echo "  "
	@echo " Note 1: <config> can be omitted if the make command is invoked from a project directory"
	@echo " Note 2: \"make <config>\" commands require the Vivado environment to be set up (see Vivado README.md)"
	@echo " Note 3: Valid <config> are:"
	@for c in $(VALID_CONFIGS); do echo "            $$c"; done

# =============================================================================
# DOCS MODE:  make docs [targets...]
#   Creates docs/.venv, pip-installs docs/ (pyproject.toml), runs make -C docs.
#   Examples:  make docs  |  make docs html  |  make docs clean  |  make docs clean html
# =============================================================================
ifeq ($(_G1),docs)

DOCS_DIR  := docs
DOCS_VENV := $(DOCS_DIR)/.venv
DOCS_GOALS := $(filter-out docs,$(MAKECMDGOALS))
ifeq ($(strip $(DOCS_GOALS)),)
  DOCS_GOALS := html
endif

.PHONY: docs
docs:
	[ -d $(DOCS_VENV) ] || python3 -m venv $(DOCS_VENV)
	$(DOCS_VENV)/bin/pip install -e $(DOCS_DIR)
	+$(MAKE) -C $(DOCS_DIR) SPHINXBUILD=$(abspath $(DOCS_VENV))/bin/sphinx-build $(DOCS_GOALS)

# Swallow goals passed after "docs" so the root make does not look for them
DOCS_PHONY := clean html html_verbose rst dirhtml singlehtml pickle json htmlhelp qthelp applehelp devhelp epub epub3 latex latexpdf latexpdfja text man texinfo info gettext changes xml pseudoxml linkcheck doctest coverage dummy help
.PHONY: $(DOCS_PHONY)
$(DOCS_PHONY): docs
	@:

# =============================================================================
# ALL CONFIGS:  make all  ->  build bitstream for every valid config (max 3 in parallel)
#   Each build removes its bitstream first; logs to xilinx_projects/chfpga_<config>/build.log
# =============================================================================
else ifeq ($(_G1),all)

.PHONY: all
all:
	@max=3; \
	configs=(); pids=(); \
	for c in $(VALID_CONFIGS); do \
	  while [ $$(jobs -r 2>/dev/null | wc -l) -ge $$max ]; do sleep 2; done; \
	  log="xilinx_projects/chfpga_$$c/build.log"; \
	  echo "Starting $$c (log: $$log)"; \
	  $(MAKE) CONFIG=$$c bitstream & \
	  configs+=("$$c"); pids+=($$!); \
	done; \
	failed=(); \
	for i in $${!pids[@]}; do \
	  if ! wait $${pids[$$i]}; then failed+=("$${configs[$$i]}"); fi; \
	done; \
	echo ""; echo "=== Build summary ==="; \
	if [ $${#failed[@]} -eq 0 ]; then echo "All configs succeeded."; \
	else echo "Failed configs: $${failed[*]}"; fi; \
	echo ""; \
	for c in $(VALID_CONFIGS); do \
	  log="xilinx_projects/chfpga_$$c/build.log"; \
	  echo "========== $$c (last 10 lines of $$log) =========="; \
	  tail -n 10 "$$log" 2>/dev/null || echo "(no log or empty)"; \
	  echo ""; \
	done

# =============================================================================
# HELP or NO GOALS:  make help  or  make  (default goal is help)
#   help target already defined at top; skip direct mode so we don't require CONFIG
# =============================================================================
else ifeq ($(_G1),help)
# no-op: help target and recipe are defined unconditionally at top
else ifeq ($(strip $(_G1)),)
# no goals given: .DEFAULT_GOAL is help; do not enter direct mode
# no-op

# =============================================================================
# WRAPPER MODE:  make <config> <action>
#   First goal is not an action; second goal is an action.
#   Re-invoke make with CONFIG= so the real targets run in a single clean pass.
# =============================================================================
else ifneq ($(filter $(_G2),$(ACTIONS)),)

.PHONY: $(_G1) $(_G2)

$(_G1):
	@+$(MAKE) CONFIG=$(_G1) $(_G2)

$(_G2): $(_G1)
	@:

# =============================================================================
# SINGLE GOAL = CONFIG:  make <config>  (re-invoke only; avoid computing DEPS twice)
# =============================================================================
else ifeq ($(words $(MAKECMDGOALS))_$(filter $(_G1),$(VALID_CONFIGS)),1_$(_G1))

.PHONY: $(_G1)
$(_G1):
	@+$(MAKE) CONFIG=$(_G1) bitstream

# =============================================================================
# DIRECT MODE:  make CONFIG=<config> <action>
#               make <action>           (from a project directory)
# =============================================================================
else

# --- Determine CONFIG ---

ifeq ($(strip $(CONFIG)),)
  ifneq ($(filter $(_G1),$(ACTIONS)),)
    # Goal is an action: infer CONFIG from the current directory name.
    CONFIG := $(patsubst chfpga_%,%,$(notdir $(CURDIR)))
  else ifneq ($(strip $(_G1)),)
    # Goal is a config name used as shorthand (default action = bitstream).
    CONFIG := $(_G1)
  endif
endif

ifeq ($(strip $(CONFIG)),)
  $(error Please set CONFIG, e.g. 'make CONFIG=crs_corr32 bitstream', or run from a project directory with '../make bitstream')
endif

# --- Require Vivado environment (project/bitstream/clean use Vivado) ---
ifeq ($(XILINX_VIVADO),)
  $(error Vivado environment not loaded. Please run: source <path-to-vivado>/settings64.sh)
endif

# --- Map CONFIG -> project directory and main project file ---
PROJECT_DIR := $(if $(PROJECT_DIR_$(CONFIG)),$(PROJECT_DIR_$(CONFIG)),xilinx_projects/chfpga_$(CONFIG))
PROJ_NAME   := $(notdir $(PROJECT_DIR))
PROJ_XPR    := $(PROJECT_DIR)/$(PROJ_NAME).xpr
PROJ_BIT    := $(PROJECT_DIR)/$(PROJ_NAME).bit

ifeq ($(wildcard $(PROJECT_DIR)/create_project.tcl),)
  $(error Config '$(CONFIG)' has no project at $(PROJECT_DIR). Valid configs: $(VALID_CONFIGS))
endif

# --- Source-file dependency list (via --list_files_only) ---
# Each repo-relative path is prefixed with FILE: in the Tcl output so we can
# reliably extract just the paths from Vivado's mixed stdout (which also
# contains startup banners and INFO messages).
DEPS := $(shell cd $(PROJECT_DIR) && $(VIVADO) -source create_project.tcl -tclargs --list_files_only 2>/dev/null | sed -n 's/^FILE://p')

# --- Real build targets ---
.PHONY: all project bitstream clean

all: bitstream

# Create/refresh the Vivado project only.
# Only re-run Vivado project creation when any dependency is newer than PROJ_XPR.
project: $(PROJ_XPR)

$(PROJ_XPR): $(DEPS)
	cd $(PROJECT_DIR) && $(VIVADO) -source create_project.tcl

# Full build: synth + impl + bitstream.
# Rebuild only when .bit is missing or older than project or any source. Log to build.log and stdout.
# Like project, phony bitstream has no recipe so Make prints "Nothing to be done" when up to date.
bitstream: $(PROJ_BIT)

$(PROJ_BIT): $(PROJ_XPR) $(DEPS)
	@cd $(PROJECT_DIR) && rm -f $(PROJ_NAME).bit && \
	( $(VIVADO) -source ../../tcl/build_project.tcl 2>&1 | tee build.log ); \
	r=$${PIPESTATUS[0]}; exit $$r

# Delete Vivado-generated artefacts (sources untouched)
clean:
	rm -rf $(PROJECT_DIR)/*.cache \
	       $(PROJECT_DIR)/*.hw    \
	       $(PROJECT_DIR)/*.runs  \
	       $(PROJECT_DIR)/*.ip_user_files \
	       $(PROJECT_DIR)/*.ip_files \
	       $(PROJ_XPR) \
	       $(PROJ_BIT)

endif
