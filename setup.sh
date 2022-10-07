#!/bin/bash

re=^[A-Za-z0-9_-]+$

project=""
while ! [[ "${project?}" =~ ${re} ]]
do
  read -p "🔷 Enter the project name (can use letters, numbers, dash or underscore): " project
done

service=""
while ! [[ "${service?}" =~ ${re} ]]
do
  read -p "🔷 Enter the micro frontend name (can use letters, numbers, dash or underscore): " service
done

repository=""
currentRepo="https://github.com/edwardramirez31/micro-frontend-utility-module"
read -p "🔷 Enter your GitHub repository URL: " repository
sed -i "s,$currentRepo,$repository,g" .releaserc
sed -i "s,$currentRepo,$repository,g" package.json

semanticReleaseRemoved=false
while true; do
    read -p "🔷 Do you want to use Semantic Release? [y/N]: " yn
    case $yn in
        [Yy]* )
          echo "⚠️  Don't forget setting ACTIONS_DEPLOY_ACCESS_TOKEN secret at your repository"
          break
        ;;
        [Nn]* )
          rm .releaserc
          sed -i.bak -e '44,48d' .github/workflows/main.yml && rm .github/workflows/main.yml.bak
          sed -i.bak -e '38,40d' package.json && rm package.json.bak
          semanticReleaseRemoved=true
          break
        ;;
        * ) echo "Please answer yes or no like: [y/N]";;
    esac
done

npmRemoved=false
while true; do
    read -p "🔷 Do you want to release this utility module to NPM? [y/N]: " yn
    case $yn in
        [Yy]* )
          echo "⚠️  Don't forget setting NPM_TOKEN secret at your repository with an NPM Automation Access Token so that your utility can be deployed to NPM"
          echo "💡 Go ahead and change the project author, description, keywords and license at package.json according to your needs"
          break
        ;;
        [Nn]* )
          rm .npmignore
          linesToRemove="49,56d"
          if [[ "$semanticReleaseRemoved" == true ]]; then
            linesToRemove="44,51d"
          fi
          sed -i.bak -e $linesToRemove .github/workflows/main.yml && rm .github/workflows/main.yml.bak
          npmRemoved=true
          break
        ;;
        * ) echo "Please answer yes or no like: [y/N]";;
    esac
done

sed -i "s/my-app/$project/g" package.json
sed -i "s/mf-app/$project/g" package.json
sed -i "s/my-app/$project/g" .github/workflows/main.yml
sed -i "s/utility-module/$service/g" package.json
sed -i "s/utility/$service/g" package.json
sed -i "s/my-app-utility/$project-$service/g" tsconfig.json
sed -i "s/'my-app'/'$project'/g" webpack.config.js
sed -i "s/utility/$service/g" webpack.config.js
mv src/my-app-utility.tsx "src/$project-$service.tsx"


echo "🔥🔨 Installing dependencies"
yarn install
echo "🔥⚙️ Installing Git Hooks"
yarn husky install
echo "🚀🚀 Project setup complete!"
echo "✔️💡 Run 'yarn start' to boot up your single-spa root config"
