dev:
	git pull
	zola serve
build:
	zola build
# save:
# 	git add content	
# 	git annex add static/media	
# 	git commit -am"maj content"
# 	git push
# 	git annex sync --content
deploy: build
	rsync -azv ./public/ root@rhumbs.fr:/var/www/misc.rhumbs.fr/

# new TITLE:
# 	./bin/new.sh "{{TITLE}}"
