# wiki

## Requirements

* sbcl
* postgresql
* fcgi
* roswell
* https://ultralisp.org/
* Atom (ubuntu install gnome tweaks and change theme to dark)
* Atom parinfer, atom-slime, language-lisp https://atom.io/packages/atom-slime

## Installation

```bash
sudo pacman -S --needed postgresql
sudo -iu postgres
initdb -D /var/lib/postgres/data
exit
sudo systemctl start postgresql
sudo -iu postgres
createuser --interactive
spickipedia
n
n
n
createdb spickipedia
exit

cd crypt_blowfish
makepkg -si
cd ..
sudo ldconfig

ln -s $PWD/spickipedia/ ~/.roswell/local-projects/
ln -s $PWD/monkeylib-bcrypt/ ~/.roswell/local-projects/
ln -s $PWD/lack/ ~/.roswell/local-projects/
ln -s $PWD/parenscript/ ~/.roswell/local-projects/

sudo ln -s $PWD/crypt_blowfish/libbcrypt.so /usr/local/lib/
sudo ldconfig

git clone https://github.com/phppgadmin/phppgadmin /usr/share/nginx/phppgadmin

(with-connection (db)
  (mito:create-dao 'user :name "Administrator" :hash (hash "xfg3zte94h62j392h") :group "admin")
  (mito:create-dao 'user :name "Anonymous" :hash (hash "xfg3zte94h") :group "anonymous")
  (mito:create-dao 'user :name "<your name>" :hash (hash "fjd8sh3l2h") :group "user"))

psql -U postgres -d spickipedia
```

```bash
npm install html-minifier -g
html-minifier --collapse-boolean-attributes --collapse-inline-tag-whitespace --collapse-whitespace --decode-entities --remove-attribute-quotes --remove-comments --remove-empty-attributes --remove-optional-tags --remove-redundant-attributes --remove-script-type-attributes --remove-style-link-type-attributes --remove-tag-whitespace --sort-attributes --sort-class-name --trim-custom-fragments --use-short-doctype -o www/index.html www/index.html
java -jar closure-compiler-v20181210.jar --js_output_file=www/s/result.js --externs externs/jquery-3.3.js www/s/jquery-3.3.1.js www/s/popper.js www/s/bootstrap.js www/s/summernote-bs4.js www/s/visual-diff.js www/s/index.js
npm i -g purgecss
purgecss --content www/index.html --css www/s/all.css --css www/s/bootstrap.min.css --css www/s/index.css --css www/s/summernote-bs4.css -o www/s/ --content www/s/*.js
```

(setup-db)
 (spickipedia:start :port 3000 :max-thread-count 100 :max-accept.count 100)
