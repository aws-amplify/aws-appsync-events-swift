# Events API Swift Integration Tests

The backend is provisioned with creating an Amplify CLI Gen 2 project by runing the following command. 

```
npm create amplify@latest
```

Update `auth/resource.ts`

```ts
import { defineAuth, defineFunction } from '@aws-amplify/backend';

export const auth = defineAuth({
  loginWith: {
    email: true,
  },
  triggers: {
    // configure a trigger to point to a function definition
    preSignUp: defineFunction({
      entry: './pre-sign-up-handler.ts'
    })
  }
});

```

Add `auth/pre-sign-up-handler.ts`

```ts
import type { PreSignUpTriggerHandler } from 'aws-lambda';

export const handler: PreSignUpTriggerHandler = async (event) => {
  // your code here
  event.response.autoConfirmUser = true
  return event;
};
```


Update `backend.ts`

```ts
import { defineBackend } from '@aws-amplify/backend'
import { auth } from './auth/resource'
import {
	AuthorizationType,
	CfnApi,
	CfnChannelNamespace,
	CfnApiKey,
} from 'aws-cdk-lib/aws-appsync'
import { Policy, PolicyStatement } from 'aws-cdk-lib/aws-iam'

const backend = defineBackend({ auth })

const customResources = backend.createStack('custom-resources-events')

const cfnEventAPI = new CfnApi(customResources, 'cfnEventAPI', {
	name: 'events',
	eventConfig: {
		authProviders: [
			{ authType: AuthorizationType.API_KEY },
			{ authType: AuthorizationType.IAM },
			{
				authType: AuthorizationType.USER_POOL,
				cognitoConfig: {
				  awsRegion: customResources.region,
				  userPoolId: backend.auth.resources.userPool.userPoolId,
				},
			}
		],
		connectionAuthModes: [
			{ authType: AuthorizationType.API_KEY },
			{ authType: AuthorizationType.IAM },
			{ authType: AuthorizationType.USER_POOL }
		],
		defaultPublishAuthModes: [
			{ authType: AuthorizationType.API_KEY },
			{ authType: AuthorizationType.IAM },
			{ authType: AuthorizationType.USER_POOL }
		],
		defaultSubscribeAuthModes: [
			{ authType: AuthorizationType.API_KEY },
			{ authType: AuthorizationType.IAM },
			{ authType: AuthorizationType.USER_POOL }
		],
	},
})

new CfnChannelNamespace(customResources, 'PentestCfnEventAPINamespace', {
	apiId: cfnEventAPI.attrApiId,
	name: 'default',
})

// attach a policy to the authenticated user role in our User Pool to grant access to the Event API:
backend.auth.resources.authenticatedUserIamRole.attachInlinePolicy(
	new Policy(customResources, 'AuthAppSyncEventPolicy', {
	  statements: [
		new PolicyStatement({
		  actions: [
			'appsync:EventConnect',
			'appsync:EventSubscribe',
			'appsync:EventPublish',
		  ],
		  resources: [`${cfnEventAPI.attrApiArn}/*`, `${cfnEventAPI.attrApiArn}`],
		}),
	  ],
	})
);

// Add the policy as an inline policy (not `addToPrincialPolicy`) to avoid circular deps
backend.auth.resources.unauthenticatedUserIamRole.attachInlinePolicy(
	new Policy(customResources, 'UnauthAppSyncEventPolicy', {
		statements: [
			new PolicyStatement({
				actions: [
					'appsync:EventConnect',
					'appsync:EventPublish',
					'appsync:EventSubscribe',
				],
				resources: [`${cfnEventAPI.attrApiArn}/*`, `${cfnEventAPI.attrApiArn}`],
			}),
		],
	})
)

// Create an API key
const apiKey = new CfnApiKey(customResources, 'EventApiKey', {
    apiId: cfnEventAPI.attrApiId,
    description: 'API Key for Event API',
    expires: Math.floor(Date.now() / 1000) + (365 * 24 * 60 * 60) // Optional: Set expiry to 1 year from now
})

backend.addOutput({
	custom: {
		events: {
			url: `https://${cfnEventAPI.getAtt('Dns.Http').toString()}/event`,
			aws_region: customResources.region,
			default_authorization_type: AuthorizationType.API_KEY,
			api_key: apiKey.attrApiKey
		},
	},
})
```

Run `npx ampx sandbox` to deploy your backend.

Once deployed, copy the `amplify_outputs.json` over to IntegrationTestApp folder `(Tests/IntegrationTestApp/IntegrationTestApp)`.