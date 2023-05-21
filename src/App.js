import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';

// import Home from './components/Home';
import Navbar from "./Components/Navbar";
import CreateNFT from "./Components/CreateNFT";
// import Profile from "./Components/Profile";

function App() {
    return (
        <Router>
            <Navbar/>
            <Routes>
                {/*<Route path="/" element={<Home />} />*/}
                <Route path="/createNFT" element={<CreateNFT />} />
                {/*<Route path="/profile" element={<Profile />} />*/}
            </Routes>
        </Router>
    );
}

export default App;


