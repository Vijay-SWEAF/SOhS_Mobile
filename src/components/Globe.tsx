import { useEffect, useRef } from "react";
import * as THREE from "three";
import { GOLD, TEAL } from "../lib/theme";

/* Dotted world globe, ported from the prototype. Loaded lazily —
   this module (and three.js with it) is only fetched at reveal. */

type Vec3 = readonly [number, number, number];

function fibonacciSphere(n: number, radius: number): Vec3[] {
  const pts: Vec3[] = [];
  const g = Math.PI * (3 - Math.sqrt(5));
  for (let i = 0; i < n; i++) {
    const y = 1 - (i / (n - 1)) * 2;
    const r = Math.sqrt(1 - y * y);
    const t = g * i;
    pts.push([Math.cos(t) * r * radius, y * radius, Math.sin(t) * r * radius]);
  }
  return pts;
}

function latLngToVec(lat: number, lng: number, radius: number): Vec3 {
  const phi = ((90 - lat) * Math.PI) / 180;
  const theta = ((lng + 180) * Math.PI) / 180;
  return [
    -radius * Math.sin(phi) * Math.cos(theta),
    radius * Math.cos(phi),
    radius * Math.sin(phi) * Math.sin(theta),
  ];
}

const HOTSPOTS: ReadonlyArray<readonly [number, number]> = [
  [28.6, 77.2], [19.1, 72.9], [13.1, 80.3],
  [35.7, 139.7], [37.5, 127.0], [31.2, 121.5],
  [51.5, -0.1], [48.9, 2.3], [52.5, 13.4],
  [40.7, -74.0], [34.0, -118.2], [19.4, -99.1],
  [-23.5, -46.6], [-34.6, -58.4],
  [6.5, 3.4], [-1.3, 36.8], [30.0, 31.2],
  [-33.9, 151.2], [25.2, 55.3], [41.0, 28.9],
];

interface GlobeProps {
  reduceMotion: boolean;
}

export default function Globe({ reduceMotion }: GlobeProps) {
  const hostRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    const host = hostRef.current;
    if (!host) return;
    const w = host.clientWidth;
    const h = host.clientHeight;
    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(42, w / h, 0.1, 100);
    camera.position.z = 2.85;
    const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
    renderer.setSize(w, h);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
    host.appendChild(renderer.domElement);

    const group = new THREE.Group();
    group.rotation.x = 0.34;
    scene.add(group);

    const base = fibonacciSphere(1150, 1);
    const bp = new Float32Array(base.length * 3);
    base.forEach((p, i) => bp.set(p, i * 3));
    const baseGeo = new THREE.BufferGeometry();
    baseGeo.setAttribute("position", new THREE.BufferAttribute(bp, 3));
    const baseMat = new THREE.PointsMaterial({
      color: new THREE.Color("#2A3352"),
      size: 0.013,
      transparent: true,
      opacity: 0,
      sizeAttenuation: true,
    });
    group.add(new THREE.Points(baseGeo, baseMat));

    const gp = new Float32Array(HOTSPOTS.length * 3);
    HOTSPOTS.forEach((ll, i) => gp.set(latLngToVec(ll[0], ll[1], 1.005), i * 3));
    const goldGeo = new THREE.BufferGeometry();
    goldGeo.setAttribute("position", new THREE.BufferAttribute(gp, 3));
    const goldMat = new THREE.PointsMaterial({
      color: new THREE.Color(GOLD),
      size: 0.045,
      transparent: true,
      opacity: 0,
      sizeAttenuation: true,
    });
    group.add(new THREE.Points(goldGeo, goldMat));

    const emb = fibonacciSphere(46, 1.004).filter((_, i) => i % 3 === 0);
    const ep = new Float32Array(emb.length * 3);
    emb.forEach((p, i) => ep.set(p, i * 3));
    const embGeo = new THREE.BufferGeometry();
    embGeo.setAttribute("position", new THREE.BufferAttribute(ep, 3));
    const embMat = new THREE.PointsMaterial({
      color: new THREE.Color(TEAL),
      size: 0.03,
      transparent: true,
      opacity: 0,
      sizeAttenuation: true,
    });
    group.add(new THREE.Points(embGeo, embMat));

    let raf = 0;
    let t = 0;
    const spin = reduceMotion ? 0.0004 : 0.0015;
    const animate = (): void => {
      t += 1;
      group.rotation.y += spin;
      const ramp = Math.min(t / 70, 1);
      baseMat.opacity = 0.8 * ramp;
      goldMat.opacity = (0.8 + 0.2 * Math.sin(t * 0.06)) * ramp;
      embMat.opacity = (0.45 + 0.25 * Math.sin(t * 0.045 + 2)) * ramp;
      renderer.render(scene, camera);
      raf = requestAnimationFrame(animate);
    };
    animate();

    return () => {
      cancelAnimationFrame(raf);
      renderer.dispose();
      [baseGeo, goldGeo, embGeo].forEach((o) => o.dispose());
      [baseMat, goldMat, embMat].forEach((o) => o.dispose());
      if (renderer.domElement.parentNode === host) host.removeChild(renderer.domElement);
    };
  }, [reduceMotion]);

  return (
    <div className="relative w-full" style={{ height: 240 }}>
      <div
        className="absolute inset-0 pointer-events-none"
        style={{
          background:
            "radial-gradient(ellipse 60% 55% at 50% 52%, rgba(228,185,104,0.12), rgba(95,208,200,0.05) 55%, transparent 75%)",
        }}
      />
      <div ref={hostRef} className="absolute inset-0" />
    </div>
  );
}
