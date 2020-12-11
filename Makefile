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
# Need to both set path and use `bash` explicitly.
SHELL := env PATH=$(PATH) /bin/bash

ifneq ($(WISEGUY_SUBPROJECT_NAME),)
	root := ..
	docs := $(root)/docs/$(WISEGUY_SUBPROJECT_NAME)
	temp := $(root)/.wiseguy/$(WISEGUY_SUBPROJECT_NAME)
	wiseguy := $(root)/node_modules/wiseguy
else
	root := .
	docs := $(root)/docs
	temp := $(root)/.wiseguy/_root
	wiseguy := $(root)/node_modules/wiseguy
endif

javascript := $(filter-out _%, $(wildcard *.js))
javascript += $(wildcard test/readme.t.js)
sources := $(patsubst %.js,$(temp)/source/%.js.js,$(javascript))
styles := $(patsubst $(docs)/css/%.less,$(docs)/css/%.css,$(wildcard $(docs)/css/*.less))
docco := $(patsubst $(temp)/source/%.js.js,$(docs)/docco/%.js.html,$(sources))
pages := $(patsubst $(docs)/html/%.html,$(docs)/%.html,$(wildcard $(docs)/html/*.html))
outputs := $(docco) $(docs)/index.html $(pages) $(styles)

ifneq ("$(wildcard $(docs)/interface.yml)","")
outputs += $(docs)/interface.html
endif

ifneq ("$(wildcard $(docs)/diary.md)","")
outputs += $(docs)/diary.html
endif

all: $(root)/docs $(outputs)

.INTERMEDIATE: $(sources)

utility=$(WISEGUY_PATH)/node_modules/.bin

utilities =$(utility)/docco
utilities+=$(utility)/edify
utilities+=$(utility)/serve
utilities+=$(utility)/lessc
utilities+=$(utility)/yaml2json

$(utilities):
	cd $(WISEGUY_PATH); \
	npm install --no-save --no-package-lock; \
	cd node_modules && patch -p 1 < ../docco.js.patch;

inspect:
	@echo path=$(WISEGUY_PATH)\; project=$(WISEGUY_SUBPROJECT_NAME)\; root=$(root)\;

$(root)/docs:
	@ \
	origin=$$(git config --get remote.origin.url); \
	echo "$$origin"; \
	git clone -b gh-pages --recursive "$$origin" $(root)/docs;

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
	{ make -f $(WISEGUY_PATH)/Makefile --no-print-directory serve & } && serve=$$!; \
	make -f $(WISEGUY_PATH)/Makefile --no-print-directory watch; \
	kill -TERM $$serve;

down:
	touch $(root)/.wiseguy/_watch

# Would have to redirect too much.
#	$(eval foo=$(shell echo 8))
#	echo -> $(foo)
#	$(eval serve=$(shell bash -c '{ /bin/echo 1 & } && echo $$!'))
#	echo -> $(serve)

watch: all
	mkdir -p $(root)/.wiseguy; \
	touch $(root)/.wiseguy/_watch; \
	fswatch --exclude '.' --include $(root)'/.wiseguy/_watch$$' --include '\.html$$' --include '\.yml$$' --include '\.pug$$' --include '\.less$$' --include '\.md$$' --include '\.js$$' docs/*.yml node_modules/wiseguy/*.pug docs/pages docs/css docs/html/*.html $(javascript) docs/*.md Makefile | while read line; \
	do \
		echo OUT-OF-DATE: $$line; \
		if [[ $$line == *_watch ]]; then \
			touch $(root)/.wiseguy/_watch; \
			exit 0; \
		else \
			make -f "$(WISEGUY_PATH)/Makefile" --no-print-directory all < /dev/null; \
			osascript -e "$$CHROME_REFRESH"; \
		fi \
	done;

$(docs)/css/%.css: $(docs)/css/%.less $(utility)/lessc
	$(utility)/lessc --include-path='$(WISEGUY_PATH)/css' $< > $@ || rm -f $@

$(temp)/source/%.js.js: %.js
	mkdir -p $(temp)/source/$(dir $<)
	cp $< $@

$(docco): $(sources) $(utility)/docco
	echo $(docco) $(sources)
	mkdir -p $(docs)/docco
	$(utility)/docco -o $(docs)/docco -c $(WISEGUY_PATH)/docco.css $(sources)
	sed -i '' -e 's/[[:space:]]*$$//' $(docs)/docco/*.js.html
	sed -i '' -e 's/\.js\.js/.js/' $(docs)/docco/*.js.html

$(docs)/docco/index.html: $(WISEGUY_PATH)/docco.pug $(docco) $(utility)/edify
	$(utility)/edify pug $$($(utility)/edify ls $(docs)/docco) < $< > $@

$(docs)/%.html: $(docs)/html/%.html $(utility)/edify
	@echo generating $@
	(cd $(docs) && \
		$(utility)/edify include --select '.include' --type text | \
	    $(utility)/edify markdown --select '.markdown' | \
	    $(utility)/edify highlight --select '.language-javascript' --language 'javascript') < $< > $@

$(docs)/diary.html: $(docs)/diary.md $(docs)/pages/diary.pug $(utility)/edify
	@echo generating $@
	@(cd $(docs) && $(utility)/edify pug <(wg diary < diary.md | jq -s .) | \
		$(utility)/edify include --select '.include' --type text | \
	    $(utility)/edify markdown --select '.markdown' | \
	    $(utility)/edify highlight --select '.lang-javascript' --language 'javascript' \
		) < $(docs)/pages/diary.pug > $@

$(docs)/interface.html: $(docs)/interface.yml $(WISEGUY_PATH)/interface.pug $(utility)/yaml2json $(utility)/edify
	($(utility)/edify pug "$$($(utility)/yaml2json $<)" | \
	    $(utility)/edify markdown --select '.markdown' | \
	    $(utility)/edify highlight --select '.lang-javascript' --language 'javascript') < $(WISEGUY_PATH)/interface.pug > $@

clean:
	rm -rf $(outputs) $(docs)/index.html $(docs)/docco .wiseguy

serve: all $(utility)/serve
	(cd $(root)/docs && $(utility)/serve --listen 4000)
