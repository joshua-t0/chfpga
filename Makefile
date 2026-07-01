#!/usr/bin/make -f

# Central Makefile for Vivado projects and docs
# ---------------------------------------------
# Usage:
#   Docs (from repo root):
#     make docs                    # build HTML (default)
#     make docs html | make docs clean | make docs clean html
#     Uses docs/pyproject.toml via uv (syncs docs/.venv automatically).
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
ACTIONS := project bitstream clean status
SHELL   := /bin/bash
MAKEFLAGS += --no-print-directory

_G1 := $(word 1,$(MAKECMDGOALS))
_G2 := $(word 2,$(MAKECMDGOALS))

# Configs = directories xilinx_projects/chfpga_* that have create_project.tcl
VALID_CONFIGS := $(sort $(foreach d,$(wildcard xilinx_projects/chfpga_*),$(if $(wildcard $(d)/create_project.tcl),$(patsubst chfpga_%,%,$(notdir $(d))),)))

# Repo-root global clean: single goal "clean", CONFIG unset, cwd = repo root (see help).
_GLOBAL_REPO_CLEAN := $(and $(filter clean,$(word 1,$(MAKECMDGOALS))),$(filter 1,$(words $(MAKECMDGOALS))),$(if $(strip $(CONFIG)),,x),$(wildcard tcl/create_generic_project.tcl),ok)

# Wrapper mode: config goals (exact names or globs like crs_*) + at most one action. Require at least one config after expansion.
_WRAP_ACT_CNT       := $(words $(filter $(ACTIONS),$(MAKECMDGOALS)))
_WRAP_CFG_GOALS     := $(filter-out $(ACTIONS),$(MAKECMDGOALS))
# Expand config goals: exact names match themselves; goals with * match VALID_CONFIGS (subst * -> % for filter).
WRAPPER_CONFIGS     := $(sort $(foreach g,$(_WRAP_CFG_GOALS),$(filter $(subst *,%,$g),$(VALID_CONFIGS))))
_WRAP_EXPANDED_CNT  := $(words $(WRAPPER_CONFIGS))
_WRAP_HAVE_EXPANDED := $(filter-out 0,$(_WRAP_EXPANDED_CNT))

.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo "Usage:"
	@echo "  "
	@echo "    make [<config> ... | <glob>] [<action>]  # e.g. crs_*; action = project|bitstream|clean|status"
	@echo "    make [<config> ...] project     # Create project for specified config(s)"
	@echo "    make [<config> ...] [bitstream]# Build bitstream for specified config(s)"
	@echo "    make [<config> ...] clean       # Clean project and bitstream (incl. .bit) for specified config(s)"
	@echo "    make clean                      # From repo root: all config build dirs + platform gen/ (from .xci/.bd sources)"
	@echo "    make [<config> ...] status      # Print build status for specified config(s)"
	@echo "    make all                    # build bitstream for every <config>"
	@echo "    make status                 # Print build status for all configs"
	@echo "    make docs [clean][html]     # Build the documentation"
	@echo "  "
	@echo " Note 1: <config> can be omitted if the make command is invoked from a project directory"
	@echo " Note 2: \"make <config>\" commands require the Vivado environment to be set up (see Vivado README.md)"
	@echo " Note 3: Valid <config> are:"
	@for c in $(VALID_CONFIGS); do echo "            $$c"; done

# =============================================================================
# DOCS MODE:  make docs [targets...]
#   Delegates to docs/Makefile (uv syncs docs/.venv from pyproject.toml).
#   Examples:  make docs  |  make docs html  |  make docs clean  |  make docs clean html
# =============================================================================
ifeq ($(_G1),docs)

DOCS_DIR  := docs
DOCS_GOALS := $(filter-out docs,$(MAKECMDGOALS))
ifeq ($(strip $(DOCS_GOALS)),)
  DOCS_GOALS := html
endif

.PHONY: docs
docs:
	+$(MAKE) -C $(DOCS_DIR) $(DOCS_GOALS)

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
	done; \
	echo "=== Error lines from build.log ==="; \
	for c in $(VALID_CONFIGS); do \
	  log="xilinx_projects/chfpga_$$c/build.log"; \
	  if [ -f "$$log" ] && grep -qE '[1-9][0-9]* [Ee]rror|ERROR\]:|ERROR:|failed' "$$log" 2>/dev/null; then \
	    echo "--- $$c ---"; \
	    grep -E '[1-9][0-9]* [Ee]rror|ERROR\]:|ERROR:|failed' "$$log" 2>/dev/null | tail -20 | sed 's/^/  /'; \
	    echo ""; \
	  fi; \
	done

# =============================================================================
# STATUS:  make status  or  make <config> status  ->  print build status per config
# =============================================================================
else ifeq ($(_G1),status)

.PHONY: status
status:
	@for c in $(if $(CONFIG),$(CONFIG),$(VALID_CONFIGS)); do \
	  dir="xilinx_projects/chfpga_$$c"; name="chfpga_$$c"; \
	  bit="$$dir/$$name.bit"; log="$$dir/build.log"; \
	  deps=""; \
	  echo ""; echo "=== $$c ==="; \
	  uptodate="(n/a)"; \
	  if lsof "$$log" >/dev/null 2>&1 || fuser -s "$$log" 2>/dev/null; then st="RUNNING"; \
	  elif [ -f "$$log" ] && grep -qE '[1-9][0-9]* [Ee]rror|ERROR\]:|ERROR:|failed' "$$log" 2>/dev/null; then st="ERROR"; \
	  elif [ ! -f "$$bit" ]; then st="MISSING"; \
	  elif [ -f "$$bit" ]; then \
	    bt=$$(stat -c %Y "$$bit" 2>/dev/null); \
	    uptodate="yes"; \
	    if [ -n "$$XILINX_VIVADO" ]; then \
	      deps=$$(cd "$$dir" && $(VIVADO) -source create_project.tcl -tclargs --list_files_only 2>/dev/null | sed -n 's/^FILE://p'); \
	      for f in $$deps; do ft=$$(stat -c %Y "$$f" 2>/dev/null); [ -f "$$f" ] && [ -n "$$bt" ] && [ -n "$$ft" ] && [ "$$bt" -lt "$$ft" ] && uptodate="no" && break; done; \
	    else \
	      uptodate="(unknown - load Vivado to check deps)"; \
	    fi; \
	    if [ "$$uptodate" = "yes" ]; then st="UP TO DATE"; \
	    elif [ "$$uptodate" = "no" ]; then st="OUT OF DATE"; \
	    else st="UP TO DATE (deps not checked)"; fi; \
	  fi; \
	  echo "  status: $$st"; \
	  if [ -f "$$bit" ]; then echo "  bitstream: $$bit"; echo "    date: $$(stat -c '%y' "$$bit" 2>/dev/null | cut -d. -f1)"; \
	  else echo "  bitstream: MISSING"; fi; \
	  [ "$$st" != "RUNNING" ] && echo "  up to date (vs listed sources): $$uptodate"; \
	  if [ -f "$$bit" ]; then \
	    [ -z "$$deps" ] && [ -n "$$XILINX_VIVADO" ] && deps=$$(cd "$$dir" && $(VIVADO) -source create_project.tcl -tclargs --list_files_only 2>/dev/null | sed -n 's/^FILE://p'); \
	    if [ -n "$$deps" ]; then \
	      dep_t=0; dep_f=""; \
	      for nf in $$deps; do \
	        [ -f "$$nf" ] || continue; \
	        nt=$$(stat -c %Y "$$nf" 2>/dev/null) || continue; \
	        [ "$$nt" -gt "$$dep_t" ] && dep_t=$$nt && dep_f=$$nf; \
	      done; \
	      if [ -n "$$dep_f" ]; then \
	        echo "  newest listed source file: $$dep_f"; \
	        echo "    date: $$(stat -c '%y' "$$dep_f" 2>/dev/null | cut -d. -f1)"; \
	      fi; \
	    fi; \
	  fi; \
	  if [ "$$st" = "ERROR" ] && [ -f "$$log" ]; then \
	    echo "  error lines from build.log:"; grep -E '[1-9][0-9]* [Ee]rror|ERROR\]:|ERROR:|failed' "$$log" 2>/dev/null | tail -10 | sed 's/^/    /'; \
	  fi; \
	  if [ -f "$$log" ]; then \
	    echo "  build.log: $$log"; echo "    build finished: $$(stat -c '%y' "$$log" 2>/dev/null | cut -d. -f1)"; \
	    dur=$$(grep -oE 'elapsed = [0-9:]+' "$$log" 2>/dev/null | tail -1); [ -n "$$dur" ] && echo "    last step elapsed: $$dur"; \
	    timing=$$(grep -E 'WNS=.*TNS=' "$$log" 2>/dev/null | tail -1); \
	    if [ -n "$$timing" ]; then \
	      wns=$$(echo "$$timing" | grep -oE 'WNS=[^ |]+' || true); tns=$$(echo "$$timing" | grep -oE 'TNS=[^ |]+' || true); \
	      whs=$$(echo "$$timing" | grep -oE 'WHS=[^ |]+' || true); ths=$$(echo "$$timing" | grep -oE 'THS=[^ |]+' || true); \
	      echo "    $$wns $$tns $$whs $$ths"; \
	    fi; \
	  else echo "  build.log: (none)"; fi; \
	done; echo ""

else ifeq ($(_G1),help)
# no-op: help target and recipe are defined unconditionally at top
else ifeq ($(strip $(_G1)),)
# no goals given: .DEFAULT_GOAL is help; do not enter direct mode
# no-op

# =============================================================================
# WRAPPER MODE:  make [<config> ... | <glob>] [<action>]
#   Config goals: exact names or globs (e.g. crs_*). At most one action. Default action = bitstream.
#   Order of configs and action does not matter (e.g. make clean kc705_corr8 = make kc705_corr8 clean).
#   Re-invoke make CONFIG=<c> <action> for each expanded config. (No config goals -> direct mode.)
# =============================================================================
else ifeq ($(filter $(_WRAP_ACT_CNT),0 1)_$(_WRAP_HAVE_EXPANDED),$(_WRAP_ACT_CNT)_$(_WRAP_EXPANDED_CNT))

WRAPPER_ACTION  := $(or $(word 1,$(filter $(ACTIONS),$(MAKECMDGOALS))),bitstream)

.PHONY: $(MAKECMDGOALS)
# Glob goals (e.g. crs_*): build expanded configs so "make crs_*" works. Escape * in target name.
$(foreach g,$(filter-out $(VALID_CONFIGS),$(_WRAP_CFG_GOALS)),$(eval $g: $(filter $(subst *,%,$g),$(VALID_CONFIGS)); @:))
# If an action is spelled as a goal (e.g. make clean crs_ct), run one sub-make per config from the
# action target only. Do not use action: $(configs) or the config goal is built twice and the second
# time Make prints "Nothing to be done for <config>".
ifeq ($(strip $(filter $(ACTIONS),$(MAKECMDGOALS))),)
$(foreach c,$(WRAPPER_CONFIGS),$(eval $c: ; @+$(MAKE) CONFIG=$c $(WRAPPER_ACTION)))
else
project bitstream clean status:
	@+for c in $(WRAPPER_CONFIGS); do $(MAKE) CONFIG=$$c $@ || exit $$?; done
$(foreach c,$(WRAPPER_CONFIGS),$(eval $c: ; @:))
endif

# =============================================================================
# GLOBAL CLEAN (repo root):  make clean
#   Removes Vivado build dirs for every config, ip_cores/*/gen next to each catalog .xci,
#   and platforms/*/bd/gen (BD + IP products). Does not require Vivado.
# =============================================================================
else ifneq ($(strip $(_GLOBAL_REPO_CLEAN)),)

.PHONY: clean
clean:
	@echo "Global clean: all FPGA project build dirs + platform ip_cores/*/gen + bd/gen"
	@for c in $(VALID_CONFIGS); do \
	  d="xilinx_projects/chfpga_$$c"; n="chfpga_$$c"; \
	  rm -rf "$$d"/*.cache "$$d"/*.hw "$$d"/*.runs "$$d"/*.ip_user_files "$$d"/*.ip_files "$$d/$$n.xpr" "$$d/$$n.bit"; \
	done
	@shopt -s nullglob; for x in hdl/platforms/*/ip_cores/*/*.xci; do \
	  [ -f "$$x" ] || continue; g="$$(dirname "$$x")/gen"; \
	  echo "  gen: $$g$$([ -d "$$g" ] && echo ' (removed)' || echo ' (absent)')"; \
	  [ -d "$$g" ] && rm -rf "$$g"; \
	done
	@shopt -s nullglob; for g in hdl/platforms/*/bd/gen; do \
	  [ -d "$$g" ] || continue; echo "  gen: $$g (removed)"; rm -rf "$$g"; \
	done

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
DEPS := $(shell cd '$(PROJECT_DIR)' && $(VIVADO) -source create_project.tcl -tclargs --list_files_only 2>/dev/null | sed -n 's/^FILE://p')

# --- Real build targets ---
.PHONY: all project bitstream clean

all: bitstream

# Create/refresh the Vivado project only.
# Only re-run Vivado project creation when any dependency is newer than PROJ_XPR.
project: $(PROJ_XPR)

$(PROJ_XPR): $(DEPS)
	cd '$(PROJECT_DIR)' && $(VIVADO) -source create_project.tcl

# Full build: synth + impl + bitstream.
# Rebuild only when .bit is missing or older than project or any source. Log to build.log and stdout.
# Like project, phony bitstream has no recipe so Make prints "Nothing to be done" when up to date.
bitstream: $(PROJ_BIT)

$(PROJ_BIT): $(PROJ_XPR) $(DEPS)
	@cd '$(PROJECT_DIR)' && rm -f $(PROJ_NAME).bit && \
	( $(VIVADO) -source ../../tcl/build_project.tcl 2>&1 | tee build.log ); \
	r=$${PIPESTATUS[0]}; exit $$r

# Delete Vivado-generated artefacts (sources untouched). Includes bitstream (.bit) and project (.xpr).
# Also removes gen/ trees for .xci and .../bd/gen for .bd listed for this config (--list_files_only).
clean:
	@pd='$(PROJECT_DIR)'; \
	echo "Deleting Vivado project build files:"; \
	for ext in .cache .hw .runs .ip_user_files .ip_files; do \
	  shopt -s nullglob; \
	  set -- "$$pd"/*"$$ext"; \
	  if [ "$$#" -eq 0 ]; then \
	    echo "  $$pd/*$$ext (absent)"; \
	  else \
	    for p in "$$@"; do \
	      echo "  $$p"; \
	      rm -rf "$$p"; \
	    done; \
	  fi; \
	  shopt -u nullglob; \
	done; \
	for p in '$(PROJ_XPR)' '$(PROJ_BIT)'; do \
	  if [ ! -e "$$p" ]; then \
	    echo "  $$p (absent)"; \
	  else \
	    echo "  $$p"; \
	    rm -rf "$$p"; \
	  fi; \
	done
	@repo=$$(cd '$(PROJECT_DIR)'/../.. && pwd); \
	cd '$(PROJECT_DIR)' || exit 1; \
	echo "Deleting platform build files:"; \
	rels=$$($(VIVADO) -source create_project.tcl -tclargs --list_files_only | sed -n 's/^FILE://p'); \
	if [ -z "$$rels" ]; then \
	  echo "  (no FILE: lines from Vivado — see messages above)"; \
	else \
	  for rel in $$rels; do \
	    case $$rel in \
	      *.xci) f="$$repo/$$rel"; \
	        if [ ! -f "$$f" ]; then echo "  (skip) catalog xci missing: $$rel"; continue; fi; \
	        g="$$(dirname "$$f")/gen"; \
	        disp="$${g#$$repo/}"; \
	        echo "  $$disp$$([ -d "$$g" ] && echo ' (removed)' || echo ' (absent)')"; \
	        [ -d "$$g" ] && rm -rf "$$g" ;; \
	      *.bd) f="$$repo/$$rel"; case $$f in */bd/gen/*) \
	        g=$$(dirname "$$(dirname "$$f")"); \
	        disp="$${g#$$repo/}"; \
	        echo "  $$disp$$([ -d "$$g" ] && echo ' (removed)' || echo ' (absent)')"; \
	        [ -d "$$g" ] && rm -rf "$$g" ;; esac ;; \
	    esac; \
	  done; \
	fi

endif
