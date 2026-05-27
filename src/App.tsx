import React, { useState, useEffect } from 'react';
import { BrowserRouter, Routes, Route, useNavigate, Link, useLocation } from 'react-router-dom';
import { 
  Upload, Sparkles, History, User, Play, Settings, ArrowRight, CheckCircle2, 
  CreditCard, Zap, ShieldCheck, Download, Lock, X, Plus, Maximize, Share2, 
  Trash2, Layers, Smartphone, Monitor, LayoutGrid, Cloud
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { Toaster, toast } from 'sonner';

// --- Theme ---
const COLORS = {
  primary: '#22D3EE', // Neon Cyan
  accent: '#8B5CF6',  // Purple
  bg: '#000000',
  card: '#0F172A',
  glass: 'rgba(255, 255, 255, 0.05)'
};

// --- Components ---

const GlassCard = ({ children, className = '', hover = false }: any) => (
  <motion.div 
    whileHover={hover ? { y: -5, scale: 1.02 } : {}}
    className={`bg-[#0F172A]/60 backdrop-blur-2xl border border-white/10 rounded-[32px] p-6 ${className}`}
  >
    {children}
  </motion.div>
);

const Navbar = () => {
  const location = useLocation();
  const navItems = [
    { icon: LayoutGrid, path: '/', label: 'Home' },
    { icon: History, path: '/library', label: 'Library' },
    { icon: Sparkles, path: '/enhance', label: 'Enhance' },
    { icon: CreditCard, path: '/wallet', label: 'Pro' },
    { icon: User, path: '/profile', label: 'Profile' }
  ];

  return (
    <nav className="fixed bottom-8 left-1/2 -translate-x-1/2 z-50 w-[90%] max-w-md">
      <div className="bg-black/80 backdrop-blur-3xl border border-white/10 rounded-full flex justify-around p-3 items-center shadow-2xl shadow-cyan-500/10">
        {navItems.map((item) => {
          const isActive = location.pathname === item.path;
          return (
            <Link key={item.path} to={item.path} className="relative group p-3">
              <item.icon size={22} className={`transition-all ${isActive ? 'text-cyan-400 scale-125' : 'text-gray-500 hover:text-white'}`} />
              {isActive && (
                <motion.div layoutId="nav" className="absolute -bottom-1 left-1/2 -translate-x-1/2 w-1 h-1 bg-cyan-400 rounded-full" />
              )}
            </Link>
          );
        })}
      </div>
    </nav>
  );
};

// --- Pages ---

const CloudLibrary = () => {
  const [videos, setVideos] = useState([
    { id: '1', title: 'Summer Cinematic', date: 'Oct 24', thumb: 'https://images.unsplash.com/photo-1492691527719-9d1e07e534b4?auto=format&fit=crop&q=80&w=300', status: 'completed', preset: '4K' },
    { id: '2', title: 'Portrait Fix', date: 'Oct 23', thumb: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=300', status: 'completed', preset: 'TikTok' },
    { id: '3', title: 'Night Rave', date: 'Oct 20', thumb: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&q=80&w=300', status: 'processing', progress: 45 },
  ]);

  return (
    <div className="min-h-screen bg-black text-white px-6 pt-16 pb-40">
      <div className="flex justify-between items-center mb-10">
        <div>
          <h1 className="text-4xl font-black italic tracking-tighter">CLOUD LIBRARY</h1>
          <p className="text-gray-500 text-xs font-bold tracking-widest mt-1">YOUR AI-ENHANCED MASTERPIECES</p>
        </div>
        <div className="w-12 h-12 rounded-2xl bg-cyan-500/10 border border-cyan-500/20 flex items-center justify-center">
          <Cloud className="text-cyan-400" size={24} />
        </div>
      </div>

      <div className="grid grid-cols-1 gap-6">
        {videos.map((v) => (
          <GlassCard key={v.id} className="relative overflow-hidden group">
            <div className="flex gap-6">
              <div className="relative w-32 h-40 rounded-2xl overflow-hidden flex-shrink-0">
                <img src={v.thumb} className="w-full h-full object-cover opacity-60" />
                {v.status === 'processing' ? (
                  <div className="absolute inset-0 bg-black/60 flex items-center justify-center">
                    <div className="text-center">
                      <span className="text-lg font-black text-cyan-400">{v.progress}%</span>
                      <div className="w-12 h-1 bg-white/10 rounded-full mt-1 overflow-hidden">
                        <div className="h-full bg-cyan-400" style={{ width: `${v.progress}%` }} />
                      </div>
                    </div>
                  </div>
                ) : (
                  <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                    <Play className="fill-white text-white" size={32} />
                  </div>
                )}
              </div>
              <div className="flex-1 py-2 flex flex-col justify-between">
                <div>
                  <div className="flex justify-between items-start">
                    <span className="text-[10px] font-black tracking-widest text-cyan-400 border border-cyan-400/20 px-2 py-0.5 rounded-full">{v.preset}</span>
                    <Trash2 className="text-gray-600 hover:text-red-400 cursor-pointer transition-colors" size={18} />
                  </div>
                  <h3 className="text-xl font-bold mt-2 truncate">{v.title}</h3>
                  <p className="text-gray-500 text-xs mt-1">{v.date}</p>
                </div>
                <div className="flex gap-3">
                  <button className="flex-1 bg-white/5 hover:bg-white/10 border border-white/10 py-2 rounded-xl text-xs font-bold transition-all">VIEW</button>
                  <button className="flex-1 bg-cyan-500 text-black py-2 rounded-xl text-xs font-bold transition-all shadow-lg shadow-cyan-500/20">DOWNLOAD</button>
                </div>
              </div>
            </div>
          </GlassCard>
        ))}
      </div>
    </div>
  );
};

const EnhanceConfig = () => {
  const [preset, setPreset] = useState('Full HD');
  const navigate = useNavigate();

  const presets = [
    { id: 'Full HD', label: 'Full HD', icon: Smartphone, desc: 'Standard 1080p high quality' },
    { id: '4K', label: '4K Ultra', icon: Monitor, desc: 'Maximum resolution & detail' },
    { id: 'TikTok', label: 'TikTok/Reels', icon: Smartphone, desc: 'Optimized 9:16 vertical 1080p' },
    { id: 'YouTube', label: 'YouTube Shorts', icon: Smartphone, desc: 'High bit-rate vertical' }
  ];

  return (
    <div className="min-h-screen bg-black text-white px-6 pt-16 pb-40">
      <h1 className="text-4xl font-black italic mb-2">PRO PRESETS</h1>
      <p className="text-gray-500 text-sm font-bold uppercase tracking-widest mb-10">Select your export destination</p>

      <div className="space-y-4">
        {presets.map((p) => (
          <GlassCard 
            key={p.id} 
            className={`cursor-pointer border-2 transition-all ${preset === p.id ? 'border-cyan-400 bg-cyan-400/5 shadow-lg shadow-cyan-400/10' : 'border-white/5'}`}
            onClick={() => setPreset(p.id)}
          >
            <div className="flex items-center gap-6">
              <div className={`w-14 h-14 rounded-2xl flex items-center justify-center ${preset === p.id ? 'bg-cyan-400 text-black' : 'bg-white/5 text-gray-500'}`}>
                <p.icon size={24} strokeWidth={3} />
              </div>
              <div>
                <h3 className="text-lg font-black">{p.label}</h3>
                <p className="text-gray-500 text-[10px] font-bold tracking-widest">{p.desc}</p>
              </div>
            </div>
          </GlassCard>
        ))}
      </div>

      <div className="fixed bottom-32 left-6 right-6">
        <button 
          onClick={() => { toast.success('Enhancement started!'); navigate('/library'); }}
          className="w-full h-20 bg-gradient-to-r from-cyan-400 to-purple-500 rounded-[32px] text-black font-black text-lg shadow-2xl shadow-cyan-500/20 active:scale-95 transition-transform"
        >
          START PRO ENHANCEMENT
        </button>
      </div>
    </div>
  );
};

// --- App Root ---

function App() {
  return (
    <BrowserRouter>
      <div className="bg-black min-h-screen font-sans">
        <Toaster position="top-center" richColors theme="dark" />
        <Routes>
          <Route path="/" element={<div className="p-20 text-center font-black text-3xl">WELCOME TO BLUERAYS PRO</div>} />
          <Route path="/library" element={<CloudLibrary />} />
          <Route path="/enhance" element={<EnhanceConfig />} />
          <Route path="/wallet" element={<div className="p-20 text-center">PRO WALLET MOCK</div>} />
          <Route path="/profile" element={<div className="p-20 text-center">PROFILE MOCK</div>} />
        </Routes>
        <Navbar />
      </div>
    </BrowserRouter>
  );
}

export default App;