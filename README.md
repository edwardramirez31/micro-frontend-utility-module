# React Micro Frontend Utility Template

## Getting Started

1. Run the script to initialize the project and install dependencies:

```bash
./setup.sh
```

2. Run `yarn start --port ${YOUR_PORT}` to run locally

3. Add your new micro frontend at the root config module inside root `index.ejs` or use [Import Map Deployer](https://github.com/Insta-Graph/import-map-deployer)

```html
<script type="systemjs-importmap">
  {
    "imports": {
      "react": "https://cdn.jsdelivr.net/npm/react@16.13.0/umd/react.production.min.js",
      "react-dom": "https://cdn.jsdelivr.net/npm/react-dom@16.13.0/umd/react-dom.production.min.js",
      "single-spa": "https://cdn.jsdelivr.net/npm/single-spa@5.3.0/lib/system/single-spa.min.js",
      "@${PROJECT_NAME}/root-config": "//localhost:9000/${PROJECT_NAME}-root-config.js",
      "@${PROJECT_NAME}/{UTILITY_MODULE_NAME}": "//localhost:${YOUR_PORT}/${PROJECT_NAME}-{UTILITY_MODULE_NAME}.js"
    }
  }
</script>
```

4. Register your utility module as external at `webpack.config.js` for each micro frontend

```js
const { merge } = require('webpack-merge');
const singleSpaDefaults = require('webpack-config-single-spa-react-ts');

module.exports = (webpackConfigEnv, argv) => {
  const defaultConfig = singleSpaDefaults({
    orgName: '${PROJECT_NAME}',
    projectName: '${MICRO_FRONTEND_NAME}',
    webpackConfigEnv,
    argv,
  });

  return merge(defaultConfig, {
    // change the placeholders
    externals: ['${PROJECT_NAME}/{UTILITY_MODULE_NAME}'],
  });
};
```

5. Import your utilities at the micro frontend and use them

```js
import { utilityName } from '@${PROJECT_NAME}/{UTILITY_MODULE_NAME}';
```

6. If you are using TypeScript at your micro frontend, it's recommended to use NPM when running `./setup.sh` and then run `yarn add @${PROJECT_NAME}/{UTILITY_MODULE_NAME}`

> This way, TypeScript will infer your types and code. Also, Jest won't fail when testing and not detecting a valid import of the utility

7. Run `yarn start` to run your root config module

8. Set `devtools` local storage key at browser console, whether your root module is running locally or it's using prod or dev environment.

```js
localStorage.setItem('devtools', true);
```

- This will use [import-map-overrides](https://github.com/single-spa/import-map-overrides/blob/main/docs/ui.md) extension. This way, you can point the import map to your micro frontend that is running locally. Extension docs here [here](https://github.com/single-spa/import-map-overrides)

## Secrets

Setup secrets for S3 bucket names and roles to deploy to AWS at GitHub actions files. Secrets needed are:

- `ACTIONS_DEPLOY_ACCESS_TOKEN`: GitHub token used by Semantic Release
- `FRONTEND_DEPLOYMENT_ROLE`: IAM Role ARN
- `BUCKET_NAME`: S3 Bucket name
- `MICRO_FRONTEND_NAME`: Micro frontend name. This will be used to create a folder where you will have your micro frontend deployed JS files
- `NPM_TOKEN`: secret at your repository with an NPM Automation Access Token so that your utility can be deployed to NPM
- `IMD_USERNAME`: Username to authenticate in case you are using import map deployer
- `IMD_PASSWORD`: Password to authenticate in case you are using import map deployer
- `IMD_HOST`: Import map deployer domain name (without https)
- `CLOUDFRONT_HOST`: Cloud front domain name (without https). This can also be Route 53, or S3 bucket domain in case you are not using CloudFront to host your import map JSON file.

## Environments

- Create `Development` and `Production` environments and set each one to deploy from `dev` and `master` branches (Selected Branches rule)

- Each environment should have its own S3 Bucket, IAM Role for deployment and CloudFront distribution

- Setup environment secrets at `Development` so that the development `FRONTEND_DEPLOYMENT_ROLE` points to a role that will interact with the development S3 `BUCKET_NAME`

- Change `environment-url` input passed down to deployment workflow so that each env will point to the corresponding CloudFront or Route 53 url

## Important notes

- Maintain consistency for the project name (all micro service and root project should have the same project name)

- It's recommended to use the root config module template from [this template](https://github.com/edwardramirez31/micro-frontend-root-template) to be consistent with project naming convention

## Import Map Deployer

- Uncomment import map step at `.github/workflows/main.yml` if you are using [Import Map Deployer](https://github.com/Insta-Graph/import-map-deployer)

```yml
- name: Update import map
  run: curl -u ${USERNAME}:${PASSWORD} -d '{ "service":"@{YOUR_ORGANZATION_NAME}/'"${MICRO_FRONTEND_NAME}"'","url":"https://'"${CLOUDFRONT_HOST}"'/'"${MICRO_FRONTEND_NAME}"'/'"${IDENTIFIER}"'/'{YOUR_ORGANZATION_NAME}-"${MICRO_FRONTEND_NAME}"'.js" }' -X PATCH https://${IMD_HOST}/services/\?env=prod -H "Accept:application/json" -H "Content-Type:application/json"
  env:
    USERNAME: ${{ secrets.IMD_USERNAME }}
    PASSWORD: ${{ secrets.IMD_PASSWORD }}
    MICRO_FRONTEND_NAME: ${{ secrets.MICRO_FRONTEND_NAME }}
    CLOUDFRONT_HOST: ${{ secrets.CLOUDFRONT_HOST }}
    IMD_HOST: ${{ secrets.IMD_HOST }}
    IDENTIFIER: ${{ github.sha }}
```

- It will send a patch request to your import map deployer server located at `${IMD_HOST}` domain name, at `/services` endpoint.

  - It sends a JSON body with the service that it want to update and the url key value pair containing the new utility module url.
  - It also sends the import map username and password in order to authenticate with the server

- If you are not using Import Map Deployer, add your compiled JS utility code at the root module import maps

  ```html
  <% if (isLocal) { %>
  <script type="systemjs-importmap">
    {
      "imports": {
        "@${PROJECT_NAME}/root-config": "//localhost:9000/${PROJECT_NAME}-root-config.js",
        "@${PROJECT_NAME}/{UTILITY_MODULE_NAME}": "//localhost:${YOUR_PORT}/${PROJECT_NAME}-{UTILITY_MODULE_NAME}.js"
      }
    }
  </script>
  <% } else { %>
  <script type="systemjs-importmap">
    {
      "imports": {
        "@${PROJECT_NAME}/root-config": "https://{S3_BUCKET_NAME}.s3.amazonaws.com/${PROJECT_NAME}-root-config.js",
        "@${PROJECT_NAME}/{UTILITY_MODULE_NAME}": "https://{S3_BUCKET_NAME}.s3.amazonaws.com/${PROJECT_NAME}-{UTILITY_MODULE_NAME}.js"
      }
    }
  </script>
  <% } %>
  ```

## Semantic Release

- Set `ACTIONS_DEPLOY_ACCESS_TOKEN` secret at your repository with a GitHub Personal Access Token so that Semantic Release can work properly

  - This token should have full control of private repositories

## Deploying Package to NPM

- Set NPM_TOKEN secret at your repository with an NPM Automation Access Token so that your utility can be deployed to NPM

> It's highly recommended to publish your package to NPM so that you don't have TypeScript errors about not finding your utility module when it is imported at your micro frontends.

- Your ${PROJECT_NAME} prompted when running ´./setup.sh´ should be the same as your organization or username from NPM. This way, you will avoid errors when executing your GitHub actions pipeline at ´npm publish --access=public´ step

> You can remove ´--access=public´ option from ´npm publish´ if you can publish private packages to NPM

- You can remove the ´.github´ folder if you don't want to use CI / CD GitHub actions for semantic release, publish to NPM, automated testing and deployment.

## Deployment in AWS

- Build the project with `yarn build` and deploy the files to a CDN (CloudFront + S3) or host to serve those static files.

- According with `.github/workflows/main.yml`, the action will assume a role through GitHub OIDC and AWS STS. This role has permissions to put new objects in your S3 bucket

  - This action step will send the build files generated at `dist` folder to `s3://${BUCKET_NAME}/${MICRO_FRONTEND_NAME}/${IDENTIFIER}`
  - That way, it will store your utility compiled code at the same folder `${MICRO_FRONTEND_NAME}` and store each new version with GitHub Commit SHA `${IDENTIFIER}`

- Import map deployer step then will update `import-map.json` file in your S3 bucket with the new compiled file route

- All the instructions to deploy the whole infrastructure to AWS are at [Micro Frontend Root Documentation](https://github.com/edwardramirez31/micro-frontend-root-layout)
