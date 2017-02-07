# Can't get this to work right now, complaints about JavaScript security. Would
# update to reload the current page if the current page was the correct page,
# rather than look through all tabs for the correct pages.
#
# http://www.finetunedmac.com/forums/ubbthreads.php?ubb=showflat&Number=40638
define SAFARI_REFRESH
tell application "Safari"
set windowList to every window
repeat with aWindow in windowList
	set tabList to every tab of aWindow
	if tabList is not equal to missing value then
		repeat with atab in tabList
			if (URL of atab contains "127.0.0.1:4000") then
			  do shell script "echo 1"
			end if
		end repeat
	end if
end repeat
end tell
endef

#			  tell atab to do javascript "window.location.reload()"

define CHROME_REFRESH
on run keyword
	tell application "Google Chrome"
		set windowList to every window
		repeat with aWindow in windowList
			set tabList to every tab of aWindow
			repeat with atab in tabList
				if (URL of atab contains "127.0.0.1:4000") then
					tell atab to reload
				end if
			end repeat
		end repeat
	end tell
end run
endef

export SAFARI_REFRESH
export CHROME_REFRESH

PATH  := "$(PATH):$(PWD)/node_modules/.bin"
SHELL := env PATH=$(PATH) /bin/sh

name := $(shell jq -r '.name' < package.json)

ifneq (,$(findstring .,$(name)))
	name := $(shell echo $(name) | sed 's/.*\.//')
	root := ..
	docs := $(root)/docs/$(name)
	temp := $(root)/.wiseguy/$(name)
else
	root := .
	docs := $(root)/docs
	temp := $(root)/.wiseguy/_root
endif

javascript := $(filter-out _%, $(wildcard *.js))
sources := $(patsubst %.js,$(temp)/source/%.js.js,$(javascript))
styles := $(patsubst $(docs)/css/%.less,$(docs)/css/%.css,$(wildcard $(docs)/css))
docco := $(patsubst $(temp)/source/%.js.js,$(docs)/docco/%.js.html,$(sources))
pages :=
ifneq (,$(docco))
pages += $(docs)/docco/index.html
endif
outputs := $(root)/docs $(docco) $(docs)/index.html $(pages)

all: $(outputs)

$(root)/docs:
	@ \
	origin=$$(git config --get remote.origin.url); \
	echo "$$origin"; \
	git clone -b gh-pages --recursive "$$origin" $(root)/docs;

$(root)/node_modules/.bin/docco:
	cd $(root); \
	mkdir -p node_modules; \
	npm install docco@0.7.0; \
	cd node_modules && patch -p 1 < wiseguy/docco.js.patch;

$(root)/node_modules/.bin/serve:
	cd $(root); \
	mkdir -p node_modules; \
	npm install serve@1.4.0;

$(root)/node_modules/.bin/lessc:
	cd $(root); \
	mkdir -p node_modules; \
	npm install less;

$(root)/node_modules/.bin/edify:
	cd $(root); \
	mkdir -p node_modules; \
	npm install less edify edify.pug edify.markdown edify.highlight edify.include edify.ls;

# Thoughts on how to capture a child pid.
#
# http://superuser.com/a/1133789
# http://superuser.com/questions/790560/variables-in-gnu-make-recipes-is-that-possible
# http://stackoverflow.com/questions/1909188/define-make-variable-at-rule-execution-time
#
# We serve in the background, then wait on the `make watch` task. The watch task
# will exit if the Makefile is determined to be out of date. Thus, we can bring
# down the background server by touching `Makefile`.
#
# Usage is to run this task in another window, which works well enough for me in
# my `tmux` enviroment. Previously, I was running `make serve` in one window and
# `make watch` in another, and then having to remember to kill before I go.
#
# All of this would probably be alot simpiler, and could really run in the
# background,  if I where to allow myself a few pid files in the build
# directory.
up:
	{ make --no-print-directory serve & } && serve=$$!; \
	make --no-print-directory watch; \
	kill -TERM $$serve;

down:
	touch Makefile

# Would have to redirect too much.
#	$(eval foo=$(shell echo 8))
#	echo -> $(foo)
#	$(eval serve=$(shell bash -c '{ /bin/echo 1 & } && echo $$!'))
#	echo -> $(serve)

watch: all
	fswatch --exclude '.' --include 'Makefile$$' --include '\.pug$$' --include '\.less$$' --include '\.md$$' --include '\.js$$' pages css $(javascript) *.md Makefile | while read line; \
	do \
		echo OUT-OF-DATE: $$line; \
		if [[ $$line == *Makefile ]]; then \
			touch Makefile; \
			exit 0; \
		else \
			make --no-print-directory all < /dev/null; \
			osascript -e "$$CHROME_REFRESH"; \
		fi \
	done;

$(root)/$(docs)/css/%.css: $(root)/$(docs)/css/%.less $(root)/node_modules/.bin/lessc
	$(root)/node_modules/.bin/lessc $< > $@ || rm -f $@

$(temp)/source/%.js.js: %.js
	mkdir -p $(temp)/source
	cp $< $@

$(docco): $(sources) $(root)/node_modules/.bin/docco
	echo $(docco) $(sources)
	mkdir -p docco
	$(root)/node_modules/.bin/docco -o $(docs)/docco -c $(root)/node_modules/wiseguy/docco.css $(temp)/source/*.js.js
	sed -i '' -e 's/[ \t]*$$//' $(docs)/docco/*.js.html
	sed -i '' -e 's/\.js\.js/.js/' $(docs)/docco/*.js.html

$(docs)/index.html: $(docs)/index.md

$(docs)/docco/index.html: $(root)/node_modules/wiseguy/docco.pug $(docco)
	$(root)/node_modules/.bin/edify pug $$($(root)/node_modules/.bin/edify ls $(docs)/docco) < $< > $@

$(docs)/%.html: $(docs)/pages/%.pug $(root)/node_modules/.bin/edify
	@echo generating $@
	@(cd $(docs) && $(root)/../node_modules/.bin/edify pug | \
		$(root)/../node_modules/.bin/edify include --select '.include' --type text | \
	    $(root)/../node_modules/.bin/edify markdown --select '.markdown' | \
	    $(root)/../node_modules/.bin/edify highlight --select '.lang-javascript' --language 'javascript') < $< > $@

clean:
	rm -f $(docco) $(docs)/index.html $(docs)/docco/*.html

serve: $(root)/node_modules/.bin/serve all
	(cd $(root)/docs && ../node_modules/.bin/serve --no-less --port 4000)
