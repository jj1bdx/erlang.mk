# Copyright (c) 2015-2016, Loïc Hoguin <essen@ninenines.eu>
# This file is part of erlang.mk and subject to the terms of the ISC License.

# Verbosity.

proto_verbose_0 = @echo " PROTO " $(filter %.proto,$(?F));
proto_verbose = $(proto_verbose_$(V))

# Core targets.

ifneq ($(wildcard src/),)
PROTO_FILES := $(filter %.proto,$(ALL_SRC_FILES))
ERL_FILES += $(addprefix src/,$(patsubst %.proto,%_pb.erl,$(notdir $(PROTO_FILES))))

ifeq ($(words $(PROTO_FILES)),0)
$(ERLANG_MK_TMP)/last-makefile-change-protobuffs:
	$(verbose) :
else
# Rebuild proto files when the Makefile changes.
# We exclude $(PROJECT).d to avoid a circular dependency.
$(ERLANG_MK_TMP)/last-makefile-change-protobuffs: $(filter-out $(PROJECT).d,$(MAKEFILE_LIST))
	$(verbose) mkdir -p $(ERLANG_MK_TMP)
	$(verbose) if test -f $@; then \
		touch $(PROTO_FILES); \
	fi
	$(verbose) touch $@

$(PROJECT).d:: $(ERLANG_MK_TMP)/last-makefile-change-protobuffs
endif

define compile_proto.erl
	[begin
		protobuffs_compile:generate_source(F,
			[{output_include_dir, "./include"},
				{output_src_dir, "./src"}])
	end || F <- string:tokens("$1", " ")],
	halt().
endef

$(PROJECT).d:: $(PROTO_FILES)
	$(verbose) mkdir -p ebin/ include/
	$(if $(strip $?),$(proto_verbose) $(call erlang,$(call compile_proto.erl,$?)))
endif
