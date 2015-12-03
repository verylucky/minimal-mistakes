sed 's/127.0.0.1/verylucky.github.io/g' _config.yml > _config.yml
./build.sh
git add -A
git commit -m "change blog"
git push origin master
sed 's/verylucky.github.io/127.0.0.1/g' _config.yml > _config.yml
