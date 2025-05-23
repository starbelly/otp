#
# %CopyrightBegin%
#
# SPDX-License-Identifier: Apache-2.0
#
# Copyright Ericsson AB 2004-2025. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# %CopyrightEnd%
#

include $(ERL_TOP)/make/target.mk
include $(ERL_TOP)/make/$(TARGET)/otp.mk

# ----------------------------------------------------
# Target Specs
# ----------------------------------------------------

MODULES= \
	ssh_cth \
	ssh_algorithms_SUITE \
	ssh_options_SUITE \
	ssh_basic_SUITE \
	ssh_bench_SUITE \
	ssh_chan_behaviours_SUITE \
	ssh_collect_labmachine_info_SUITE \
	ssh_compat_SUITE \
	ssh_connection_SUITE \
	ssh_agent_mock_server \
	ssh_agent_SUITE \
	ssh_dbg_SUITE \
	ssh_engine_SUITE \
	ssh_protocol_SUITE \
	ssh_property_test_SUITE \
	ssh_pubkey_SUITE \
	ssh_renegotiate_SUITE \
	ssh_sftp_SUITE \
	ssh_sftpd_SUITE \
	ssh_sftpd_erlclient_SUITE \
	ssh_sup_SUITE \
	ssh_to_openssh_SUITE \
	ssh_upgrade_SUITE \
	ssh_test_lib \
	ssh_log_h \
	ssh_key_cb \
	ssh_key_cb_options \
	ssh_key_cb_engine_keys \
	ssh_trpt_test_lib \
	ssh_chan_behaviours_client \
	ssh_chan_behaviours_server \
	ssh_echo_server \
	ssh_bench_dev_null \
	ssh_peername_sockname_server \
	ssh_test_cli \
	ssh_relay \
	ssh_eqc_event_handler

ERL_FILES= $(MODULES:%=%.erl)

HRL_FILES= \
	$(ERL_TOP)/lib/ssh/test/ssh_test_lib.hrl \
	$(ERL_TOP)/lib/ssh/src/ssh.hrl \
	$(ERL_TOP)/lib/ssh/src/ssh_agent.hrl \
	$(ERL_TOP)/lib/ssh/src/ssh_auth.hrl \
	$(ERL_TOP)/lib/ssh/src/ssh_connect.hrl \
	$(ERL_TOP)/lib/ssh/src/ssh_transport.hrl \
	$(ERL_TOP)/lib/ssh/src/ssh_xfer.hrl


TARGET_FILES= $(MODULES:%=$(EBIN)/%.$(EMULATOR))

SPEC_FILES = \
	ssh.spec \
	ssh_bench.spec \
	ssh_sup.spec

COVER_FILE = ssh.cover

EMAKEFILE=Emakefile
MAKE_EMAKE = $(wildcard $(ERL_TOP)/make/make_emakefile)

# ----------------------------------------------------
# Release directory specification
# ----------------------------------------------------
RELSYSDIR = $(RELEASE_PATH)/ssh_test

# ----------------------------------------------------
# FLAGS
# ----------------------------------------------------

INCLUDES = -I$(ERL_TOP)/lib/ssh/src

ERL_COMPILE_FLAGS += $(INCLUDES) -pa ../ebin +nowarn_missing_spec_documented
ERL_COMPILE_FLAGS := $(filter-out +deterministic,$(ERL_COMPILE_FLAGS))

EBIN = .

# ----------------------------------------------------
# Targets
# ----------------------------------------------------

tests $(TYPES): emakebuild $(TARGET_FILES)

.PHONY: emakebuild

emakebuild: $(EMAKEFILE)

$(EMAKEFILE):
	$(MAKE_EMAKE) $(ERL_COMPILE_FLAGS) -o$(EBIN) '*_SUITE_make' | grep -v Warning > $(EMAKEFILE)
	$(MAKE_EMAKE) $(ERL_COMPILE_FLAGS) -o$(EBIN) $(MODULES) | grep -v Warning >> $(EMAKEFILE)

clean:
	rm -f $(EMAKEFILE)
	rm -f $(TARGET_FILES)
	rm -f core

docs:

# ----------------------------------------------------
# Release Target
# ----------------------------------------------------
include $(ERL_TOP)/make/otp_release_targets.mk

release_spec: opt

release_tests_spec: opt
	$(INSTALL_DIR) "$(RELSYSDIR)"
	$(INSTALL_DATA) $(EMAKEFILE) "$(RELSYSDIR)"
	$(INSTALL_DATA) $(SPEC_FILES) $(COVER_FILE) "$(RELSYSDIR)"
	$(INSTALL_DATA) $(ERL_FILES)    "$(RELSYSDIR)"
	$(INSTALL_DATA) $(HRL_FILES)    "$(RELSYSDIR)"
	$(INSTALL_DATA) $(TARGET_FILES) "$(RELSYSDIR)"
	chmod -R u+w "$(RELSYSDIR)"
	@tar cf - *_SUITE_data property_test | (cd "$(RELSYSDIR)"; tar xf -)

release_docs_spec:
