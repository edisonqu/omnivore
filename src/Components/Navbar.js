function Navbar() {
    return (
        <nav className="flex items-center justify-between p-6 bg-black">
            <div className="text-white">
                <a href="/" className="font-bold text-2xl">Omnivore</a>
            </div>
            <div>
                <a href="/createNFT" className="text-white mr-4">Create NFT</a>
                <a href="/profile" className="text-white">Profile</a>
            </div>
        </nav>
    );
}

export default Navbar;
