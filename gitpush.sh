sed 's/127.0.0.1:4000/verylucky.github.io/g' _config.yml > tmpfile
mv tmpfile _config.yml
./build.sh
git add -A
git commit -m "change blog"
git push origin master
sed 's/verylucky.github.io/127.0.0.1:4000/g' _config.yml > tmpfile
mv tmpfile _config.yml
