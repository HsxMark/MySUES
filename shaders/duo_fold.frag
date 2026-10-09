#version 320 es

// Duo fold — Flutter port of duo-open's res/raw/duo_unfold.agsl
// (github.com/marcoazeem/duo-open), itself an AGSL port of
// github.com/Atomicx7/Duo-animation, itself a port of the Three.js reference at
// github.com/chuspeeism/iphone-duo.
//
// Model:
// - The UI lives on a fixed plane: where the screen would be if it were flat.
//   Its image is what we sample; it never moves.
// - The eye sits still on that plane's normal through the hinge, so you look
//   into the half-open device the way you look into a book.
// - A pane of frosted glass — one half of the display, bent about the hinge —
//   is what you look *through*. `u_paneSide` names the half that bends; the
//   other half is passed through untouched and stays crisp.
// - Per pixel: cast a ray from the eye through the glass point, continue it
//   onto the plane, and show what it lands on. The blur radius and the
//   darkening grow with the glass/plane gap, so the crease stays sharp and the
//   far edge frosts over until the device is fully open.
//
// Distances are expressed relative to the size of the bound texture, so the
// result does not depend on whether the engine hands us physical or logical
// pixels. Only the physical length of the split axis is needed, for the
// per-millimetre darkening.
//
// Uniforms are declared in this order because Flutter assigns float slots by
// declaration order: `u_size` takes slots 0 and 1 and is filled in by the
// engine (see `ImageFilter.shader`), so the first float we set ourselves is
// slot 2.

#include <flutter/runtime_effect.glsl>

// Engine-provided: the size of the bound texture.
uniform vec2 u_size;
// Engine-provided: the filter input, i.e. the content on the flat plane.
uniform sampler2D u_texture;

uniform float u_tilt;            // glass tilt in radians; 0 disables the effect
uniform float u_hingeFrac;       // hinge position along the split axis, 0..1
uniform float u_eyeFrac;         // eye position along the split axis, 0..1
uniform float u_eyeDistanceFrac; // eye distance, as a multiple of the split axis
uniform float u_paneSide;        // -1 left pane bends, +1 right pane, 0 both
uniform float u_axisSwap;        // 0 hinge splits x (vertical line), 1 splits y
uniform float u_blurSpread;      // blur radius gained per unit of glass/plane gap
uniform float u_darkeningPerMm;  // fraction of light lost per mm of blur radius
uniform float u_splitExtentMm;   // physical length of the split axis, in mm

out vec4 frag_color;

const float GOLDEN_ANGLE = 2.39996322972865332;
const float TWO_PI = 6.28318530717958648;

vec4 contentAt(vec2 coord) {
  return texture(u_texture, clamp(coord / u_size, vec2(0.0), vec2(1.0)));
}

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;

  if (u_size.x <= 1.0 || u_size.y <= 1.0 || u_tilt < 1e-4) {
    frag_color = contentAt(fragCoord);
    return;
  }

  // Work in a frame where the hinge is always a vertical line.
  vec2 p = mix(fragCoord, fragCoord.yx, u_axisSwap);
  vec2 size = mix(u_size, u_size.yx, u_axisSwap);
  float hingePos = u_hingeFrac * size.x;
  float eyeDistance = u_eyeDistanceFrac * size.x;

  float side = mix(-1.0, 1.0, step(hingePos, p.x));
  if (u_paneSide * side < -0.5) {
    frag_color = contentAt(fragCoord);  // the half held still stays flat
    return;
  }

  float d = abs(p.x - hingePos);        // distance from the hinge along the glass
  float c = cos(u_tilt);
  float s = sin(u_tilt);

  // The glass, foreshortened by cos and lifted off the plane by d * sin.
  vec2 glass = vec2(hingePos + side * d * c, p.y);
  float gap = d * s;
  // The eye sits on the hinge for a split screen, and at the centre of the
  // window for the single-pane cover screen.
  vec2 eye = vec2(u_eyeFrac * size.x, size.y * 0.5);

  // Ray eye -> glass pixel, continued onto the plane.
  float depth = eyeDistance - gap;
  if (depth <= 1e-3) {
    frag_color = vec4(0.0, 0.0, 0.0, 1.0);
    return;
  }
  vec2 hitS = eye + (glass - eye) * (eyeDistance / depth);

  float radius = u_blurSpread * gap;

  // The whole blur kernel misses the plane: nothing to show through the glass.
  if (hitS.x < -radius || hitS.y < -radius ||
      hitS.x > size.x + radius || hitS.y > size.y + radius) {
    frag_color = vec4(0.0, 0.0, 0.0, 1.0);
    return;
  }

  vec2 hit = mix(hitS, hitS.yx, u_axisSwap);

  // Frosted glass absorbs: dim in proportion to how much it scatters. The
  // radius is in texture pixels, so convert it to millimetres first.
  float mmPerPx = u_splitExtentMm / size.x;
  float atten = max(1.0 - u_darkeningPerMm * radius * mmPerPx, 0.0);

  if (radius < 0.5) {
    frag_color = vec4(contentAt(hit).rgb * atten, 1.0);
    return;
  }

  // Vogel disk with a per-pixel rotation, so the sampling pattern reads as
  // frost instead of banding. A fixed 32-iteration loop with a weight mask
  // keeps frames cheap near the hinge.
  float tapsF = clamp(radius * 2.0, 6.0, 32.0);
  float rotation = fract(sin(dot(fragCoord, vec2(12.9898, 78.233))) * 43758.5453) * TWO_PI;
  vec3 sum = vec3(0.0);
  float wsum = 0.0;
  for (int i = 0; i < 32; i++) {
    float fi = float(i);
    float w = 1.0 - step(tapsF, fi);
    float r = radius * sqrt((fi + 0.5) / tapsF);
    float a = fi * GOLDEN_ANGLE + rotation;
    sum += contentAt(hit + r * vec2(cos(a), sin(a))).rgb * w;
    wsum += w;
  }
  frag_color = vec4((sum / max(wsum, 1.0)) * atten, 1.0);
}
