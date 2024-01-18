import { readFileSync } from 'fs';
import { join } from 'path';
import { config } from 'dotenv';
config();
import { getOrCreateAssociatedTokenAccount, createTransferInstruction } from "@solana/spl-token";
import { Connection, Keypair, ParsedAccountData, PublicKey, sendAndConfirmTransaction, Transaction } from "@solana/web3.js";

// Read environment variables
const secretString: string = process.env.SECRET || (() => { throw new Error("SECRET not found in .env file"); })();
const receiversJsonFilename: string = process.env.RECEIVERS_JSON_FILENAME || (() => { throw new Error("RECEIVERS_JSON_FILENAME not found in .env file"); })()
const connectionURL: string = process.env.SOLANA_CONNECTION_URL || (() => { throw new Error("SOLANA_CONNECTION_URL not found in .env file"); })()
const tokenAddress: string = process.env.TOKEN_ADDRESS || (() => { throw new Error("TOKEN_ADDRESS not found in .env file"); })();
const transferAmount: number = process.env.TRANSFER_AMOUNT ? parseInt(process.env.TRANSFER_AMOUNT, 10) : (() => { throw new Error("transferAmount not found in .env file"); })();

// Initialize global variables
const secret = secretString.split(',').map(num => parseInt(num, 10));
const fromKeypair = Keypair.fromSecretKey(new Uint8Array(secret));
const connection = new Connection(connectionURL, "confirmed");
const receivers: string[] = JSON.parse(readFileSync(join(__dirname, receiversJsonFilename), 'utf8'));

const getNumberDecimals = async (): Promise<number> => {
    const info = await connection.getParsedAccountInfo(new PublicKey(tokenAddress));
    const result = (info.value?.data as ParsedAccountData).parsed.info.decimals as number;
    return result;
}

const sendToken = async (destinationAddress: string) => {
    let sourceAccount = await getOrCreateAssociatedTokenAccount(
        connection,
        fromKeypair,
        new PublicKey(tokenAddress),
        fromKeypair.publicKey
    );

    let destinationAccount = await getOrCreateAssociatedTokenAccount(
        connection,
        fromKeypair,
        new PublicKey(tokenAddress),
        new PublicKey(destinationAddress)
    );

    const numberDecimals = await getNumberDecimals();

    const tx = new Transaction();
    tx.add(createTransferInstruction(
        sourceAccount.address,
        destinationAccount.address,
        fromKeypair.publicKey,
        transferAmount * Math.pow(10, numberDecimals)
    ))

    const latestBlockHash = await connection.getLatestBlockhash('confirmed');
    tx.recentBlockhash = await latestBlockHash.blockhash;
    const signature = await sendAndConfirmTransaction(connection, tx, [fromKeypair]);

    console.log(`Transaction Success! https://explorer.solana.com/tx/${signature}?cluster=devnet`);
}

function delay<T>(ms: number, action: (arg: T) => Promise<void>, arg: T): Promise<void> {
    return new Promise(resolve => setTimeout(() => resolve(action(arg)), ms));
}

(async function main(): Promise<void> {
    try {
        const sendPromises = new Array<Promise<void>>();
        for (let i = 0; i < receivers.length; i++) {
            sendPromises.push(delay(400*i, sendToken, receivers[i]));
        }
        await Promise.all(sendPromises);
    } catch (error) {
        console.error("Error in transactions:", error);
    }
})();