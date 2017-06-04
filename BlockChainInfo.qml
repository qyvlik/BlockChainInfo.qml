//! [WebSocket API Real-Time blockchain data](https://blockchain.info/api/api_websocket)
//! [blockchain/api-v1-client-node](https://github.com/blockchain/api-v1-client-node)

import QtQuick 2.0
import QtWebSockets 1.0

QtObject {
    id: blockChainInfo

    readonly property url blockChainInfoWSUrl: "wss://ws.blockchain.info/inv"

    signal connecting(string errorString)
    signal open(string errorString)
    signal closing(string errorString)
    signal closed(string errorString)
    signal error(string errorString)

    signal transaction(var txObj)
    signal block(var blockObj)
    signal message(string operation, var messageObj)

    property alias ping: timer.running
    property bool subscribingAfterActive: true
    property alias active: webSocket.active

    readonly property WebSocket __webSocket: WebSocket {
        id: webSocket

        url: blockChainInfoWSUrl

        onTextMessageReceived: {
            var messageObj = JSON.parse(message);

            var op = messageObj.op;
            var xData = messageObj.x;
            if (op === 'utx') {
                transaction(xData);
            } else if (op === 'block') {
                block(xData);
            } else {
                blockChainInfo.message(op, xData);
            }
        }

        onStatusChanged: {
            switch(webSocket.status)
            {
            case WebSocket.Connecting:
                blockChainInfo.connecting(webSocket.errorString);
                break;
            case WebSocket.Open:
                blockChainInfo.open(webSocket.errorString);
                break;
            case WebSocket.Closing:
                blockChainInfo.closing(webSocket.errorString);
                break;
            case WebSocket.Closed:
                blockChainInfo.closed(webSocket.errorString);
                break;
            case WebSocket.Error:
            default:
                blockChainInfo.error(webSocket.errorString);
                break;
            }
        }
    }

    readonly property Timer __timer: Timer {
        id: timer
        interval: 30000
        repeat: true
        running: true
        onTriggered: {
            subscribing('ping');
        }
    }

    onActiveChanged: {
        if (active && subscribingAfterActive) {
            __subscribingAll();
        }
    }

    function subscribing(operation, data) {
        data = data || {};
        data['op'] = operation;
        var messageStr = JSON.stringify(data);
        webSocket.sendTextMessage(messageStr);
        console.debug("subscribing sendTextMessage:", messageStr);
    }

    function whenTransaction(callback) {
        callback = callback || function(txObj){};
        subscribing('unconfirmed_sub');
        transaction.connnect(callback);
    }

    function whenBlock(callback) {
        callback = callback || function(blockObj){};
        subscribing('blocks_sub');
        block.connnect(callback);
    }

    function __subscribingAll() {
        function subAll() {
            console.debug("__subscribingAll, subAll");
            subscribing('unconfirmed_sub');
            subscribing('blocks_sub');
        }

        function afterSubAll() {
            console.debug("__subscribingAll, subAll");
            __singalConnectOnce(blockChainInfo.open, function(){
                subAll();
            });
        }

        var readySend = active && webSocket.status === WebSocket.Connecting;

        var nil = readySend ? subAll()
                            : afterSubAll();

    }

    function __singalConnectOnce(singalObject, callable) {
        if(typeof singalObject === 'undefined') {
            throw "singalObject is undefined!";
        }

        singalObject.connect(function() {
            callable.call({}, arguments);                   // {} mean thisArg
            singalObject.disconnect(arguments.callee);
        });
    }

}
