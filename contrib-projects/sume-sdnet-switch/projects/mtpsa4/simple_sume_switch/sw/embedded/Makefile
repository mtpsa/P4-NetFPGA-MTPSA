WS	= SDK_Workspace
PROJ	= ${NF_PROJECT_NAME}

.PHONY: distclean clean project compile download

all:
	@echo ""
	@echo "NetFPGA-SUME Reference Project SW Makefile"
	@echo ""
	@echo "make TARGETS"
	@echo "------------------------------------------------------"
	@echo "project:         Create software project"
	@echo "compile:         Compile specified project"
	@echo "download:        Download and run specified project via xmd"
	@echo ""
	@echo "clean:           Remove specified project"
	@echo "distclean:       Remove all generated projects"
	@echo ""

project:
	@if [ -d ./${WS} ]; then rm -rf ./${WS}; fi
	mkdir ./${WS}
	xsdk -batch -source ./tcl/${PROJ}_xsdk.tcl

# Compile Command needs to run twice to get sw compiled correctly in DEBUG mode
compile:
	@if [ -d ./${WS} ]; then \
		cp -a ./src/. ./${WS}/${PROJ}/app/src/; \
		xsdk -wait -eclipseargs -nosplash -application org.eclipse.cdt.managedbuilder.core.headlessbuild -build all -data ./${WS}/${PROJ} -vmargs -Dorg.eclipse.cdt.core.console=org.eclipse.cdt.core.systemConsole; \
		xsdk -wait -eclipseargs -nosplash -application org.eclipse.cdt.managedbuilder.core.headlessbuild -build all -data ./${WS}/${PROJ} -vmargs -Dorg.eclipse.cdt.core.console=org.eclipse.cdt.core.systemConsole; \
	else \
		echo "SDK_Workspace not found"; \
	fi

download:
	@if [ -d ./../bitfiles ]; then \
		xmd -tcl ./tcl/download.tcl `find ./../bitfiles -name "*.bit"`; \
	else \
		echo "Bitfile folder not found"; \
	fi

clean:
	rm -rf ./${WS}
	rm -rf *.log
	rm -rf *.jou

distclean:
	rm -rf `find . -name "${WS}"`
	rm -rf `find . -name "*.log"`
	rm -rf `find . -name "*.jou"`

