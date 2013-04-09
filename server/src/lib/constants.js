module.exports = {
	events: {
		CONNECT: 'connection',
		DISCONNECT: 'disconnect',
		AUTH: 'authenticate',
		DEAUTH: 'deauthenticate',
		MESSAGE: 'push',
		ALIAS: 'alias',
		SUBSCRIBE: 'subscribe',
		UNSUBSCRIBE: 'unsubscribe'
	},
	res: {
		AUTH_ERROR: 'auth-error',
		AUTH_INVALID: 'auth-invalid',
		AUTH_SUCCESS: 'authenticated',
		AUTH_INVALID_PERMS: 'auth-invalid-perms',
		DEAUTH_SUCCESS: 'deauthenticated',
		CREATE_INVALID_NAME: 'create-invalid-name',
		CREATE_ALREADY_TAKEN: 'create-already-taken'
	},
	props: {
		AUTH: 'auth',
		ALIAS: 'alias',
		SUBSCRIPTIONS: 'subscriptions'
	}
};