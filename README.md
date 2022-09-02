# Task

It is a well-known fact that EVM smart contracts don’t support triggers, a contract can’t automatically call itself, and each action must be initiated by an external actor. It limits the business logic that can be implemented on-chain and makes the development process more difficult. As a DeFi protocol, we must monitor multiple conditions and respond to them quickly. Keepers have a special role, being responsible for this. It’s an off-chain component that monitors on-chain conditions and sends necessary transactions. Keepers are rewarded for their activity.

Think of the Keeper's job as processing user requests that should be executed when certain conditions are met. Different requests may have different execution conditions and requests can be added or canceled by users at any moment. The Keeper does not know when and how many conditions are met. Therefore, the conditions must be checked at every point in time. A Keeper should send a transaction to execute a request ASAP when its conditions are reached – a small delay of several minutes is applicable – otherwise, the system may face financial losses.

 We need a decentralized layer of Keepers because a single Keeper brings the risks of centralization that DeFi aims to avoid. One request can’t be executed twice, so only the first Keeper is rewarded, which creates a race between Keepers where each of them wants their transactions to be executed faster than others and they overpay for gas. Keepers are trustless; all their actions are verified on-chain and a Keeper can stop working anytime.

You need to create a consensus algorithm that helps Keepers to work in the most efficient way.

You should describe the idea of your consensus and implement the on-chain part of it. 
Propose a way how Keepers can optimize the monitoring and execution of multiple requests.
You can change the initial smart contract but not the execution condition.


# How to start
```
yarn install

yarn hardhat node
yarn deploy
```

# About ElementManager.sol
You have array with Elements
```
struct Element {
        uint256 id;
        bool isClosable;
}

Element[] public override elements;
```

If `Element.isClosable == true` you should `closeElements()` it

`Element.isClosable` can be changed at any time. You should update info about elements.

# Rules
- You are not allowed to change the code with a comment `// DON'T CHANGE`:
  - sizeLimit;
  - constructor();
  - _shakeElements();
- You are not allowed to add an event about a `Element.isClosable` change
- Everything else can be changed. You can add methods, change code, write your own contracts, and so on.
- If you feel like you need to change what is forbidden, you can try changing it. But it is better to contact us through the organizers.
- If you find a bug in our code please let us know.


