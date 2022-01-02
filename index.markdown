---
layout: default
---
<div class="greet-container px-3">
    <h1 id="greet" class="font-weight-bold">Hello, I'm Chengrui!</h1>
    <script>
        function sleep(ms) {
            return new Promise(resolve => setTimeout(resolve, ms))
        }
        async function dynamicGreet() {
            const greetings = ["Hello, I'm Chengrui!", "Hallo, ik ben Chengrui!", "你好, 我叫程睿!"];
            let greet = document.querySelector("h1");
            let n = 1;
            while (true) {
                await sleep(5000);
                greet.textContent = greetings[n];
                n = (n + 1) % 3;
            }
        }
        dynamicGreet()
    </script>
    <p id="self-intro">
    I'm a <b>Cloud Engineer</b> in the <b>Netherlands</b>. I recently started my career as a <b>developer</b> at <a href="https://www.vodafoneziggo.nl/en/">VodafoneZiggo</a>. I love <b>coding</b>. And now, coding in the <b>Cloud</b> really starts to grow on me. As my journey continues, I think it's a cool idea to share what I've done and <a href="{{ site.baseurl }}/blog/">what I've learned</a> with you.
    <br/> 
    For my fellow Chinese students who want to have a live in NL, I will also share some tips. And hopefully, they can help you avoid some pitfalls along the way. 
    </p>
    <div>
        <img src="assets/images/selfie.png" id="selfie">
    </div>
    

</div>