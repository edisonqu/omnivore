import { useEffect, useState } from 'react';
import { ethers } from 'ethers';

function Navbar() {
    const [walletAddress, setWalletAddress] = useState('');

    useEffect(() => {
        // Check if Metamask is installed
        if (typeof window.ethereum !== 'undefined') {
            connectWallet();
        }
    }, []);

    const connectWallet = async () => {
        try {
            // Request access to the user's MetaMask wallet
            await window.ethereum.request({ method: 'eth_requestAccounts' });

            // Create an ethers provider with the current provider
            const provider = new ethers.providers.Web3Provider(window.ethereum);

            // Get the user's address
            const signer = provider.getSigner();
            const address = await signer.getAddress();

            setWalletAddress(address);
        } catch (error) {
            console.error(error);
        }
    };

    const disconnectWallet = async () => {
        try {
            // Disconnect the wallet
            await window.ethereum.request({
                method: 'wallet_requestPermissions',
                params: [{ eth_accounts: {} }],
            });

            setWalletAddress('');
        } catch (error) {
            console.error(error);
        }
    };

    const formatAddress = (address) => {
        if (address) {
            const shortAddress = `${address.slice(0, 6)}...${address.slice(-4)}`;
            return (
                <span
                    className="overflow-hidden max-w-28 whitespace-nowrap overflow-ellipsis"
                    title={address}
                >
          {shortAddress}
        </span>
            );
        }
        return '';
    };

    return (
        <nav className="flex items-center justify-between p-6 bg-black">
            <div className="text-white">
                <a href="/" className="font-bold text-2xl">
                    Omnivore
                </a>
            </div>
            <div className="flex items-center space-x-4">
                <a href="/createNFT" className="text-white">
                    Create NFT
                </a>
                <a href="/profile" className="text-white">
                    Profile
                </a>
                {walletAddress ? (
                    <div className="flex items-center">
            <span className="text-white mr-2">
              {formatAddress(walletAddress)}
            </span>
                        <button
                            className="bg-blue-500 text-white px-4 py-2 rounded"
                            onClick={disconnectWallet}
                        >
                            Disconnect
                        </button>
                    </div>
                ) : (
                    <button
                        className="bg-blue-500 text-white px-4 py-2 rounded"
                        onClick={connectWallet}
                    >
                        Connect Wallet
                    </button>
                )}
            </div>
        </nav>
    );
}

export default Navbar;
