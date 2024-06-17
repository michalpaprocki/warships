// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin");
const fs = require("fs");
const path = require("path");

module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/warships_web.ex",
    "../lib/warships_web/**/*.*ex",
  ],
  theme: {
    extend: {
      borderRadius:{
        "bottom-md": "0px 0px 8px 8px",
        "top-md": "8px 8px 0px 0px "
      },
      boxShadow: {
        "glow": "0rem 0rem 1rem var(--glow_color)",
        "glow_accented": "0rem 0rem 3rem 6px var(--glowAccented_color)",
      },
      keyframes: {
        moveX : {
          "0%": {
            backgroundPosition: "100% 0%"
          }, 
          "100%" :{
            backgroundPosition: "0% 0%"
          }
        },
        pendulumFromTop: {
          "0%, 100%": {
            transform: "translateY(-50%)",
          },
          "50%": {
            transform: "translateY(50%)",
          },
        },
        pendulumFromCenter: {
          "33%": {
            transform: "translateY(50%)",
          },
          "0%, 100%": {
            transform: "translateY(-50%)",
          },
        },
        pendulumFromBottom: {
          "0%, 100%": {
            transform: "translateY(50%)",
          },
          "50%": {
            transform: "translateY(-50%)",
          },
        },
        dolphin: {
          "0%":{
            transform: "translateX(-100%) translateY(50%)",
            opacity: "0"
          },
          "50%": {
            transform: "translateY(-20%)",
            opacity: "1"
          },
          "100%":{
            transform: "translateX(100%) translateY(50%)",
            opacity: "0"

          }
        },
        dolph_ver:{
          "0%": {
            top: "0%",
          },
          "100%": {
            top: "-5%",   
          }
        },
        dolph_hor :{
          to: {
            left: "50%"
          }
        },
        fade_in_out: {
          "0%, 100%" :{
            opacity: "0"
          },
          "25% , 75%":{
            opacity: "1"
          },
      },
      fade_in: {
        "0%" :{
          opacity: "0"
        },
        "100%":{
          opacity: "1"
        },
    },
      hue_rotate: {
        "0%, 100%": { 
          filter: "hue-rotate(0deg)" 
        },
        "50%": { 
          filter: "hue-rotate(-15deg)" 
        },
      },
      shoot: {
        "0%, 100%": { 
          boxShadow: "inset 0rem 0rem 0rem red" 
        },
        "50%": {  
          boxShadow: "inset 0rem 0rem 1rem red" 
        }, 
      },
      alert: {
        "0%, 100%": { 
          boxShadow: "inset 0rem 0rem 0rem var(--alert_color)" 
        },
        "50%": {  
          boxShadow: "inset 0rem 0rem 0.5rem black" 
        }, 
      },
      traverse_y :{
        "0%": {
          top: "-30%"
        },
        "49%": {
           top: "-30%"
        },
        "51%": {
          top:"120%"
        },
        "100%": {
          top:"120%"
        }
      },
      traverse_x :{
        "0%": {
          left: "-30%"
        },
        "49%": {
           left: "-30%"
        },
        "51%": {
          left:"110%"
        },
        "100%": {
          left:"110%"
        }
      },
      pos_right: {
        "0%": {
          transform: "translateX(100%)"
        }
      },
      pos_reset: {
        "0%": {
          transform: "translateX(0%)"
        }
      },
      },
      animation: {
        pendulumTop:
          "pendulumFromTop 1s cubic-bezier(0.2, 1.5, 0.2, 0.4) infinite",
        pendulumCenter:
          "pendulumFromCenter 1.5s cubic-bezier(0.2, 1.5, 0.2, 0.4) infinite",
        pendulumBottom:
          "pendulumFromBottom 1s cubic-bezier(0.2, 1.5, 0.2, 0.4) infinite",
        miss_dolph: "dolphin 2s cubic-bezier(.29,.67,.3,.68) infinite",
        dolph_: "dolph_ver 2s .2s  cubic-bezier(.25,7,.75,7) forwards, dolph_hor 2s .2s cubic-bezier(.5,.75,.75,.5) forwards, fade_in_out 2s .2s cubic-bezier(.5,.5,.5,1)",
        fade_in_out: "fade_in_out 1s ease infinite",
        fade_in: "fade_in 0.5s ease forwards",
        hue_rotate: "hue_rotate 10s linear infinite",
        shoot_now: "shoot 2s linear infinite",
        alert: "alert 2s ease-in-out infinite",
        traverse_y: "traverse_y 20s cubic-bezier(0.4, .4, 1, 0.7) infinite",
        traverse_x: "traverse_x 25s cubic-bezier(0.7, 1, .4, 0.4) infinite",
        move_right: "pos_right 1s 2s cubic-bezier(0.7, 1, .4, 0.4) forwards",
        move_reset: "pos_reset 1s 2s cubic-bezier(0.7, 1, .4, 0.4) forwards",
        roll_right: "moveX 5s linear infinite"
      },  
      height: {
        header: "var(--headerH)",
        footer: "var(--footerH)",
      },
      minHeight: {
        "screen-header": [
          "calc(100vh - calc(var(--headerH) + var(--footerH)))",
          "calc(100dvh - calc(var(--headerH) + var(--footerH)))",
        ],
      },
      colors: {
        brand: "#FD4F00",
      },
      
      backgroundImage: {
        "stripes": "linear-gradient(45deg, var(--stripes_color) 25%, transparent 25%, transparent 50%, var(--stripes_color) 50%, var(--stripes_color) 75%, transparent 75%, transparent 100%)",
        "net_miss": "linear-gradient(45deg, var(--miss_color) 25%, transparent 25%, transparent 50%,var(--miss_color) 50%, var(--miss_color) 75%, transparent 75%, transparent 100%), linear-gradient(-45deg, var(--miss_color) 25%, transparent 25%, transparent 50%,var(--miss_color) 50%, var(--miss_color) 75%, transparent 75%, transparent 100%)",
        "net_hit": "linear-gradient(45deg, var(--hit_color) 25%, transparent 25%, transparent 50%,var(--hit_color) 50%, var(--hit_color) 75%, transparent 75%, transparent 100%), linear-gradient(-45deg, var(--hit_color) 25%, transparent 25%, transparent 50%,var(--hit_color) 50%, var(--hit_color) 75%, transparent 75%, transparent 100%)",
        "net_sunk": "linear-gradient(45deg, var(--sunk_color) 25%, transparent 25%, transparent 50%,var(--sunk_color) 50%, var(--sunk_color) 75%, transparent 75%, transparent 100%), linear-gradient(-45deg, var(--sunk_color) 25%, transparent 25%, transparent 50%,var(--sunk_color) 50%, var(--sunk_color) 75%, transparent 75%, transparent 100%)",
        "warships": "url('/images/warships.svg')",
        "warships_sm": "url('/images/warships_sm.svg')"
    },
      backgroundSize: {
        "3x3": "3rem 3rem",
        "2x2": "2rem 2rem",
        "1x1": "1rem 1rem",
        "0.75x0.75": "0.75rem 0.75rem",
        "0.5x0.5": "0.5rem 0.5rem",
        "0.25x0.25": "0.25rem 0.25rem",
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({ addVariant }) =>
      addVariant("phx-no-feedback", [".phx-no-feedback&", ".phx-no-feedback &"])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-click-loading", [
        ".phx-click-loading&",
        ".phx-click-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-submit-loading", [
        ".phx-submit-loading&",
        ".phx-submit-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-change-loading", [
        ".phx-change-loading&",
        ".phx-change-loading &",
      ])
    ),

    // Embeds Heroicons (https://heroicons.com) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function ({ matchComponents, theme }) {
      let iconsDir = path.join(__dirname, "../deps/heroicons/optimized");
      let values = {};
      let icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"],
        ["-micro", "/16/solid"],
      ];
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).forEach((file) => {
          let name = path.basename(file, ".svg") + suffix;
          values[name] = { name, fullPath: path.join(iconsDir, dir, file) };
        });
      });
      matchComponents(
        {
          hero: ({ name, fullPath }) => {
            let content = fs
              .readFileSync(fullPath)
              .toString()
              .replace(/\r?\n|\r/g, "");
            let size = theme("spacing.6");
            if (name.endsWith("-mini")) {
              size = theme("spacing.5");
            } else if (name.endsWith("-micro")) {
              size = theme("spacing.4");
            }
            return {
              [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
              "-webkit-mask": `var(--hero-${name})`,
              mask: `var(--hero-${name})`,
              "mask-repeat": "no-repeat",
              "background-color": "currentColor",
              "vertical-align": "middle",
              display: "inline-block",
              width: size,
              height: size,
            };
          },
        },
        { values }
      );
    }),
  ],
};
