# BlockChainInfo.qml

blockchain.info websocket api warp by qml

```
BlockChainInfo {
    id: blockChainInfo
    active: true
    subscribingAfterActive: true

    onTransaction: {
        console.info("txid:", txObj.hash);
    }

    onBlock: {
        console.info(blockObj.hash);
    }

    onMessage: {
        console.info(operation, messageObj);
    }

    onError: {
        console.error(errorString);
    }
}
```
