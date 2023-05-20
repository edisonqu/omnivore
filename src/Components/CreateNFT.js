import React, { useState } from 'react';

const CreateNFT = () => {
    const [name, setName] = useState("");
    const [description, setDescription] = useState("");
    const [price, setPrice] = useState("");
    const [image, setImage] = useState(null);
    const [currentChain, setCurrentChain] = useState("");
    const [targetChain, setTargetChain] = useState("");

    const handleSubmit = (e) => {
        e.preventDefault();

        // TODO: Handle this data for submission to the blockchain
    };

    const handleImageUpload = (e) => {
        const file = e.target.files[0];
        const reader = new FileReader();

        reader.onload = (event) => {
            setImage(event.target.result);
        };

        if (file) {
            reader.readAsDataURL(file);
        }
    };

    return (
        <div className="bg-black min-h-screen flex items-center justify-center">
            <div className="w-2/3 p-8 rounded">
                <h1 className="text-3xl text-white mb-8 text-center">Create NFT</h1>
                <form onSubmit={handleSubmit} className="space-y-4">
                    <input
                        type="text"
                        value={name}
                        onChange={(e) => setName(e.target.value)}
                        placeholder="NFT Name"
                        className="w-full p-2 border border-gray-300 rounded bg-gray-800 text-white"
                    />
                    <textarea
                        value={description}
                        onChange={(e) => setDescription(e.target.value)}
                        placeholder="NFT Description"
                        className="w-full p-2 border border-gray-300 rounded bg-gray-800 text-white"
                    />
                    <input
                        type="text"
                        value={price}
                        onChange={(e) => setPrice(e.target.value)}
                        placeholder="NFT Price"
                        className="w-full p-2 border border-gray-300 rounded bg-gray-800 text-white"
                    />
                    <div className="text-center">
                        <input
                            type="file"
                            onChange={handleImageUpload}
                            className="w-full p-2 border border-gray-300 rounded bg-gray-800 text-white"
                        />
                        {image && (
                            <img
                                src={image}
                                alt="Preview"
                                className="mt-4 mx-auto max-w-full h-auto"
                            />
                        )}
                    </div>
                    <select
                        value={currentChain}
                        onChange={(e) => setCurrentChain(e.target.value)}
                        className="w-full p-2 border border-gray-300 rounded bg-gray-800 text-white"
                    >
                        <option value="">Current Chain</option>
                        <option value="ethereum">Ethereum</option>
                        <option value="bsc">Binance Smart Chain</option>
                        <option value="polygon">Polygon</option>
                        {/* Add more options as needed */}
                    </select>
                    <select
                        value={targetChain}
                        onChange={(e) => setTargetChain(e.target.value)}
                        className="w-full p-2 border border-gray-300 rounded bg-gray-800 text-white"
                    >
                        <option value="">Target Chain</option>
                        <option value="ethereum">Ethereum</option>
                        <option value="bsc">Binance Smart Chain</option>
                        <option value="polygon">Polygon</option>
                        {/* Add more options as needed */}
                    </select>
                    <button
                        type="submit"
                        className="bg-blue-500 text-white px-4 py-2 rounded justify-center w-full"
                    >
                        Submit
                    </button>
                </form>
            </div>
        </div>
    );
};

export default CreateNFT;
