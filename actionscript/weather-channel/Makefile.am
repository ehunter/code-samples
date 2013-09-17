channelid = litl_weather
channeldir = $(datadir)/big/swf/$(channelid)

output_path = $(top_builddir)/build
channelzip = $(output_path)/deploy.zip

ANTARGS = -Dbuild.properties.path=${srcdir}/build.properties.template \
	  -Dflex.sdk.home=${LITL_FLEX_HOME} \
	  -Dlitl.sdk.core.path=$(SDKCOREDIR) \
	  -Dlitl.sdk.controls.path=$(SDKCONTROLSDIR) \
	  -Dlitl.sdk.helpers.path=$(SDKHELPERSDIR) \
	  -Doutput.path=$(output_path)

all-local: $(channelzip)

clean-local:
	$(ANT) $(ANTARGS) clean
	-rmdir $(output_path)

$(channelzip): # NOTE: missing dependency checking
	$(ANT) $(ANTARGS) build-release-zip

install-data-local: $(channelzip)
	$(INSTALL) -d $(DESTDIR)$(channeldir)
	$(UNZIP) -o $(channelzip) -d $(DESTDIR)$(channeldir)
	$(SHA1SUM) $(channelzip) |cut -d' ' -f 1 > $(DESTDIR)$(channeldir)/checksum

dist-hook:
	test -d $(top_srcdir)/.git
	git archive HEAD | tar xf - -C $(top_distdir)
