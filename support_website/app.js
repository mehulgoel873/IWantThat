particlesJS('particles-js',

  {
    "particles": {
      "number": {
        "value": 80,
        "density": {
          "enable": true,
          "value_area": 600
        }
      },
      "color": {
        "value": "#465048"
      },
      "shape": {
        "type": "circle",
        "stroke": {
          "width": 0,
          "color": "#000000"
        },
        "polygon": {
          "nb_sides": 5
        },
        "image": {
          "src": "img/github.svg",
          "width": 100,
          "height": 100
        }
      },
      "opacity": {
        "value": 0.8,
        "random": false,
        "anim": {
          "enable": false,
          "speed": 1,
          "opacity_min": 0.1,
          "sync": false
        }
      },
      "size": {
        "value": 6,
        "random": true,
        "anim": {
          "enable": false,
          "speed": 10,
          "size_min": 0.1,
          "sync": false
        }
      },
      "line_linked": {
        "enable": true,
        "distance": 125,
        "color": "#465048",
        "opacity": 1,
        "width": 2
      },
      "move": {
        "enable": true,
        "speed": 2,
        "direction": "none",
        "random": false,
        "straight": false,
        "out_mode": "out",
        "attract": {
          "enable": false,
          "rotateX": 600,
          "rotateY": 1200
        }
      }
    },
    "interactivity": {
      "detect_on": "canvas",
      "events": {
        "onhover": {
          "enable": true,
          "mode": "repulse"
        },
        "onclick": {
          "enable": true,
          "mode": "push"
        },
        "resize": true
      },
      "modes": {
        "grab": {
          "distance": 400,
          "line_linked": {
            "opacity": 1
          }
        },
        "bubble": {
          "distance": 400,
          "size": 40,
          "duration": 2,
          "opacity": 8,
          "speed": 3
        },
        "repulse": {
          "distance": 200
        },
        "push": {
          "particles_nb": 4
        },
        "remove": {
          "particles_nb": 2
        }
      }
    },
    "retina_detect": true,
    "config_demo": {
      "hide_card": false,
      "background_color": "#b61924",
      "background_image": "",
      "background_position": "50% 50%",
      "background_repeat": "repeat",
      "background_size": "cover"
    }
  }

);

function typing_animation() {
  let text_element = document.querySelector(".typing-container .text");
  let text_array = text_element.innerHTML.split("");
  let text_array_slice = text_element.innerHTML.split(" ");
  let text_len = text_array.length;
  console.log(text_len)

  const word_len = text_array_slice.map((word) => {
    return word.length;
  })

  console.log(word_len);

  let timings = {
    easing: `steps(${Number(word_len[0] + 1)}, end)`,
    delay: 1000,
    duration: 2000,
    fill: 'forwards'
  }

  let cursor_timings = {
    duration: 700,
    iterations: Infinity,
    easing: 'cubic-bezier(0,.26,.44,.93)'
  }

  document.querySelector(".text_cursor").animate([
    {
      opacity: 0
    },
    {
      opacity: 0, offset: 0.7
    },
    {
      opacity: 1
    }
  ], cursor_timings);

  if (text_array_slice.length == 1) {
    timings.easing = `steps(${Number(word_len[0])}, end)`;

    let reveal_animation = document.querySelector(".text_hide").animate([
      { left: '0%' },
      { left: `${(100 / text_len) * (word_len[0])}%` }
    ], timings);

    document.querySelector(".text_cursor").animate([
      { left: '0%' },
      { left: `${(100 / text_len) * (word_len[0])}%` }
    ], timings);

    reveal_animation.onfinish = () => {
      setTimeout(() => {
        document.querySelector('.text_hide').animate([
          { left: '0%' }
        ], {
          duration: 2000,
          easing: 'cubic-bezier(.73,0,.38,.88)'
        });
        document.querySelector('.text_cursor').animate([
          { left: '0%' }
        ], {
          duration: 2000,
          easing: 'cubic-bezier(.73,0,.38,.88)'
        });
        typing_animation();
      }, 1000);
    }
  } else {
    document.querySelector(".text_hide").animate([
      { left: '0%' },
      { left: `${(100 / text_len) * (word_len[0] + 1)}%` }
    ], timings);

    document.querySelector(".text_cursor").animate([
      { left: '0%' },
      { left: `${(100 / text_len) * (word_len[0] + 1)}%` }
    ], timings);
  }


  for (let i = 1; i < text_array_slice.length; i++) {
    // console.log(word_len);
    // console.log(text_array_slice.length);
    const single_word_len = word_len[i];
    // console.log(single_word_len);

    if (i == 1) {
      var left_instance = (100 / text_len) * (word_len[i - 1] + 1);
      // console.log(left_instance);
    }

    let timings_2 = {
      easing: `steps(${Number(single_word_len + 1)}, end)`,
      delay: (2 * (i + 1) + (2 * i)) * (700),
      // delay: ((i*2)-1)*1000,
      duration: 2000,
      fill: 'forwards'
    }

    if (i == (text_array_slice.length - 1)) {
      timings_2.easing = `steps(${Number(single_word_len)}, end)`;
      let reveal_animation = document.querySelector(".text_hide").animate([
        { left: `${left_instance}%` },
        { left: `${left_instance + ((100 / text_len) * (word_len[i]))}%` }
      ], timings_2);

      document.querySelector(".text_cursor").animate([
        { left: `${left_instance}%` },
        { left: `${left_instance + ((100 / text_len) * (word_len[i]))}%` }
      ], timings_2);

      reveal_animation.onfinish = () => {
        setTimeout(() => {
          document.querySelector('.text_hide').animate([
            { left: '0%' }
          ], {
            duration: 1500,
            easing: 'cubic-bezier(.73,0,.38,.88)'
          });
          document.querySelector('.text_cursor').animate([
            { left: '0%' }
          ], {
            duration: 1500,
            easing: 'cubic-bezier(.73,0,.38,.88)'
          });
          typing_animation();
        }, 1000);
      }
    } else {
      document.querySelector(".text_hide").animate([
        { left: `${left_instance}%` },
        { left: `${left_instance + ((100 / text_len) * (word_len[i] + 1))}%` }
      ], timings_2);

      document.querySelector(".text_cursor").animate([
        { left: `${left_instance}%` },
        { left: `${left_instance + ((100 / text_len) * (word_len[i] + 1))}%` }
      ], timings_2);
    }

    left_instance = left_instance + ((100 / text_len) * (word_len[i] + 1));
  }
}
typing_animation();