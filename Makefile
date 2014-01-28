# Make this RabbitMQ plugin
EXCHANGE:=rabbitmq-jms-topic-exchange
ARTEFACT:=rabbitmq_jms_topic_exchange

# Normally overridden on commandline (to include rjms version suffix)
MAVEN_ARTEFACT:=$(ARTEFACT).ez

# Version of plugin artefact to build: must be supplied on commandline
# RJMS_VERSION:=
# Version of RabbitMQ to build against: must be supplied on commandline
# RMQ_VERSION:=

HG_BASE:=http://hg.rabbitmq.com

RABBIT_DEPS:=rabbitmq-server rabbitmq-erlang-client rabbitmq-codegen
UMBRELLA:=rabbitmq-public-umbrella
RMQ_VERSION_TAG:=rabbitmq_v$(subst .,_,$(RMQ_VERSION))
RJMS_APP_SRC:=$(EXCHANGE)/src/$(ARTEFACT).app.src

# command targets ##################################
.PHONY: all clean package dist init cleandist test run-in-broker

all: dist

clean:
	rm -rf $(UMBRELLA)*
	rm -rf target*

dist: init
	$(MAKE) -C $(UMBRELLA)/$(EXCHANGE) VERSION=$(RMQ_VERSION) dist

package: dist
	mkdir -p target/plugins
	cp $(UMBRELLA)/$(EXCHANGE)/dist/$(ARTEFACT)* target/plugins/$(MAVEN_ARTEFACT)

init: $(addprefix $(UMBRELLA)/,$(EXCHANGE) $(RABBIT_DEPS))

test: dist
	$(MAKE) -C $(UMBRELLA)/$(EXCHANGE) VERSION=$(RMQ_VERSION) test

cleandist: init
	$(MAKE) -C $(UMBRELLA)/$(EXCHANGE) VERSION=$(RMQ_VERSION) clean

run-in-broker: dist
	$(MAKE) -C $(UMBRELLA)/$(EXCHANGE) VERSION=$(RMQ_VERSION) run-in-broker

# artefact targets #################################
$(UMBRELLA).co:
	hg clone $(HG_BASE)/$(UMBRELLA)
	cd $(UMBRELLA); hg up $(RMQ_VERSION_TAG)
	touch $@

$(UMBRELLA)/$(EXCHANGE): $(UMBRELLA).co $(EXCHANGE)/src/* $(EXCHANGE)/test/src/* $(EXCHANGE)/include/*
	rm -rf $(UMBRELLA)/$(EXCHANGE)
	cp -R $(EXCHANGE) $(UMBRELLA)/.
	sed -e 's|@RJMS_VERSION@|$(RJMS_VERSION)|' <$(RJMS_APP_SRC) >$(UMBRELLA)/$(RJMS_APP_SRC)

$(addprefix $(UMBRELLA)/,$(RABBIT_DEPS)): $(UMBRELLA).co
	rm -rf $@
	cd $(UMBRELLA);hg clone $(HG_BASE)/$(notdir $@)
	cd $@; hg up $(RMQ_VERSION_TAG)
