{% set site = pillar['project'] %}

# Set a role for nginx
set-nginx-role:
  grains.list_present:
    - name: roles
    - value: nginx

nginx:
  pkg:
    - installed
  service:
    - running
    - enable: True
    - require:
      - pkg: nginx
      - file: /var/cache/nginx/microcache
    - watch: 
      - file: /etc/nginx

/var/cache/nginx/microcache:
  file:
    - directory
    - user: nginx
    - group: nginx
    - mode: 750
    - makedirs: True

/var/log/nginx:
  file:
    - directory
    - user: nginx
    - group: nginx
    - mode: 755
    - makedirs: True

/etc/nginx:
  file.recurse:
    - source: salt://sites/{{ site }}/nginx
    - user: root
    - group: root
    - template: jinja
    - include_empty: True

{% if pillar.get('ssl_key') %}
/etc/nginx/ssl/server.key:
  file.managed:
    - mode: 600
    - source: salt://sites/{{ site }}/nginx/ssl/server.key
    - template: jinja
{% endif %}

/var/www/vhosts:
  file:
    - directory
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

{% for siteuser in pillar['siteuser'] %}
usermod -a -G {{ siteuser }} nginx:
  cmd.run

  {% for instance in pillar['instances'] %}
# make vhost dir for each instance and siteuser
/var/www/vhosts/{{ siteuser }}.{{ instance }}:
  file:
    - directory
    - user: {{ siteuser }}
    - group: {{ siteuser }}
    - mode: 2770

  {% endfor %}
{% endfor %}

