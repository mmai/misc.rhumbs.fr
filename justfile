dev:
	devenv up
build:
	zola build
	jaq --from-file json-feed.jaq public/dump.xml > public/feed.json
	rm public/dump.xml
# save:
# 	git add content	
# 	git annex add static/media	
# 	git commit -am"maj content"
# 	git push
# 	git annex sync --content
deploy: build
	rsync -azv ./public/ root@rhumbs.fr:/var/www/misc.rhumbs.fr/

new TITLE:
	./bin/new.sh "{{TITLE}}"
stats:
  ssh -t root@rhumbs.fr goaccess /var/log/nginx/misc_access.log --log-format=COMBINED -o /var/www/misc.rhumbs.fr/webstats.html
  firefox https://misc.rhumbs.fr/webstats.html
