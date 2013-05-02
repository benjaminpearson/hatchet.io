//
//	SocketIoClient.h
//	SocketIoCocoa
//
//	Heavily based on:
//	https://github.com/fpotter/socketio-cocoa
//	https://github.com/pkyeck/socket.IO-objc (This library is more maintained and might be worth switching to)

#import <Foundation/Foundation.h>

@class WebSocket;
@protocol SocketIoClientDelegate;

typedef enum {
	SocketIoMessageTypeDisconnect = 0,
	SocketIoMessageTypeConnect,
	SocketIoMessageTypeHeartbeat,
	SocketIoMessageTypeMessage,
	SocketIoMessageTypeJSON,
	SocketIoMessageTypeEvent,
	SocketIoMessageTypeACK,
	SocketIoMessageTypeError,
	SocketIoMessageTypeNoop,
} SocketIoMessageType;

typedef enum {
	SocketIoConnectionTypeHandshake = 0,
	SocketIoConnectionTypeForceDisconnect,
} SocketIoConnectionType;

@interface SocketIoClient : NSObject {
	NSString *_host;
	NSInteger _port;
	WebSocket *_webSocket;

	NSTimeInterval _connectTimeout;
	BOOL _tryAgainOnConnectTimeout;

	NSTimeInterval _heartbeatTimeout;
	NSTimeInterval _heartbeatIntervalPadding;

	NSTimer *_timeout;

	BOOL _isConnected;
	BOOL _isConnecting;

	NSString *_sessionId;
	NSString *_transport;

	id<SocketIoClientDelegate> _delegate;

	NSMutableArray *_queue;

	NSUInteger _ackCount;
	NSMutableDictionary *_ackCallbacks;

	int _connectRetries;
	int _maxConnectRetries;

	BOOL _secureConnection;
}

@property (nonatomic, readonly) BOOL isConnected;
@property (nonatomic, readonly) BOOL isConnecting;
@property (nonatomic, assign) BOOL secureConnection;

@property (nonatomic, assign) id<SocketIoClientDelegate> delegate;

@property (nonatomic, assign) NSTimeInterval connectTimeout;
@property (nonatomic, assign) BOOL tryAgainOnConnectTimeout;

@property (nonatomic, assign) NSTimeInterval heartbeatTimeout;
@property (nonatomic, assign) NSTimeInterval heartbeatIntervalPadding;

@property (nonatomic, assign, readonly) int connectRetries;
@property (nonatomic, assign) int maxConnectRetries;



- (id)initWithHost:(NSString *)host port:(int)port;
- (void)connect;
- (void)disconnect;

/**
 * Rather than coupling this with any specific JSON library, you always
 * pass in a string (either _the_ string, or the the JSON-encoded version
 * of your object), and indicate whether or not you're passing a JSON object.
 */

- (void)sendMessage:(NSString *)message;
- (void)sendMessage:(NSString *)message withAcknowledgeBlock:(void (^)(id json))ackBlock;
- (void)sendJSON:(id)object;
- (void)sendJSON:(id)object withAcknowledgeBlock:(void (^)(id json))ackBlock;
- (void)sendEvent:(NSString *)event withData:(id)data;
- (void)sendEvent:(NSString *)event withData:(id)data withAcknowledgeBlock:(void (^)(id json))ackBlock;

@end

@protocol SocketIoClientDelegate <NSObject>

/**
 * Message is always returned as a string, even when the message was meant to come
 * in as a JSON object.	 Decoding the JSON is left as an exercise for the receiver.
 */
- (void)socketIoClient:(SocketIoClient *)client didReceiveJSON:(id)json;
- (void)socketIoClient:(SocketIoClient *)client didReceiveMessage:(NSString *)message;
- (void)socketIoClient:(SocketIoClient *)client didReceiveEvent:(NSString *)event withData:(id)data;

- (void)socketIoClientDidConnect:(SocketIoClient *)client;
- (void)socketIoClientDidDisconnect:(SocketIoClient *)client;
- (void)socketIoClientDidDisconnectPermanently:(SocketIoClient *)client;

@optional

- (void)socketIoClient:(SocketIoClient *)client didSendJSON:(id)json;
- (void)socketIoClient:(SocketIoClient *)client didSendMessage:(NSString *)message;
- (void)socketIoClient:(SocketIoClient *)client didSendEvent:(NSString *)event withData:(id)data;

@end