# Send Token Script

## Environment Variables
```
# solana account secret that used to do mint and transfer
SECRET=

# solana api connection endpoint
SOLANA_CONNECTION_URL=

# custom spl token
TOKEN_ADDRESS=

# receivers json file
RECEIVERS_JSON_FILENAME=

# token amount (without decimals)
TRANSFER_AMOUNT=
```

## Receivers JSON format example
```
[
    "3uQpE2rTv1K7ATejjsP2fd2w7276nzu1zV2FDnsPiEm6",
    "FaYFEn5H5KHQx6haaCwT5sRc3r1r3ohaPfZZ5j9Dh6qS",
    "4dSM5DYEqnhkdrHoZj7LxwztjSm8Z9pU5ew4x5PtopFi",
    ...
    ...
    ...
    "BE1Fw482T9fBuGf21BbEe2Kf3gAUmy15itR44YiQjR2G"
]
```

## Usage
```
yarn install
ts-node sendToken.ts
```