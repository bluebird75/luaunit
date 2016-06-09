#
# junitxml/Makefile
#

XMLLINT ?= xmllint
TEST_APACHE  = --noout --schema junit-apache-ant.xsd
TEST_JENKINS = --noout --schema junit-jenkins.xsd

validate-examples: validate-apache validate-jenkins

# This example file is the only one that satisfies the Apache schema
validate-apache: example-apache-ant.xml
	$(XMLLINT) $(TEST_APACHE) $<

# The Jenkins schema is more relaxed, and should apply to all .xml files
validate-jenkins: $(wildcard *.xml)
	for file in $^; do $(XMLLINT) $(TEST_JENKINS) $$file || exit 1; done
