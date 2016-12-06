VNFD_DIRS:= server_vnfd tse_vnfd

VNFD_OUTPUT:= $(addprefix build/,$(addsuffix .tar.gz, $(VNFD_DIRS)))
VNFD_CHECKSUMS:= $(addsuffix /checksums.txt, $(VNFD_DIRS))
VNFD_YAML:= $(addsuffix .yaml, $(VNFD_DIRS))
VNFD_YAML_CLEAN:= $(addsuffix .clean, $(VNFD_YAML))
VNFD_CLOUD_INIT:= $(addsuffix /cloud_init/cloud_init.cfg,$(VNFD_DIRS))

SSH_KEY ?= ""

server_vnfd_IMAGE ?= "Ubuntu 16.04.1 LTS - Xenial Xerus - 64-bit - Cloud Based Image"
tse_vnfd_IMAGE    ?= "TSE_1.00.00-0075_x86_64_el7.pts_tse_dev_integration"

all:  $(VNFD_CLOUD_INIT) build_dir
	$(MAKE) $(VNFD_OUTPUT)

%.tar.gz: TARGET_VNFD=$(notdir $*)

%.tar.gz:
	echo "building $(TARGET_VNFD)"
	@cat $(TARGET_VNFD)/template/$(TARGET_VNFD).yaml | sed -e 's/vnfd:image:.*/vnfd:image: $($(TARGET_VNFD)_IMAGE)/g' > $(TARGET_VNFD)/$(TARGET_VNFD).yaml
	@cd $(TARGET_VNFD); find . -type f -not -path "*/template" -not -path "*/template/*" | xargs md5sum > checksums.txt; cd ..
	@tar --exclude=template -cvf build/$(TARGET_VNFD).tar $(TARGET_VNFD)/* > /dev/null
	@gzip build/$(TARGET_VNFD).tar

$(VNFD_CLOUD_INIT): VNFD_DIR=$(shell dirname $(shell dirname $@))

$(VNFD_CLOUD_INIT):
	@cat $(VNFD_DIR)/template/cloud_init.cfg > $@	
	@echo "" >> $@
	@echo "ssh_authorized_keys:" >> $@
	@echo "  - $(SSH_KEY)" >> $@

%.yaml.clean:
	@rm -f $*/$*.yaml

build_dir:
	@mkdir -p build

.PHONY: build_dir

clean:  $(VNFD_YAML_CLEAN)
	@rm -f $(VNFD_CHECKSUMS)
	@rm -f $(VNFD_CLOUD_INIT)
	@rm -f build/*
	-@rmdir build 2> /dev/null
