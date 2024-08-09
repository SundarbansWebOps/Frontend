<template>
    <NavBar></NavBar>
    <div id="chat-container-wrapper">
      <h1>Sundarbans AI Chatbot</h1>
      <div id="chat-container" ref="chatContainer">
        <div id="output" ref="output"></div>
      </div>
      <form @submit.prevent="handleSubmit" id="inputForm">
        <input
          type="text"
          id="textInput"
          v-model="question"
          placeholder="Enter your question"
          required
        />
        <button type="submit" id="submitButton">Submit</button>
        <button type="button" id="stopButton" @click="handleStop">Stop</button>
      </form>
    </div>
  </template>
  
  <script>
  import { marked } from 'marked';
  import NavBar from './NavBar.vue';
  
  export default {
    name: 'ChatBot',
    data() {
      return {
        question: '',
        reader: null,
        isStreaming: false,
        currentBotBubble: null,
        messageHistory: []
      };
    },
    components: {
      NavBar
    },
    methods: {
      async handleSubmit() {
        const question = this.question;
  
        // Add user input to the message history
        this.messageHistory.push({ role: 'user', content: question });
  
        // Add user input bubble
        const userBubble = document.createElement('div');
        userBubble.className = 'bubble user-bubble';
        userBubble.textContent = question;
        this.$refs.output.appendChild(userBubble);
  
        // Clear the input field
        this.question = '';
  
        // Hide submit button and show stop button
        document.getElementById('submitButton').style.display = 'none';
        document.getElementById('stopButton').style.display = 'inline';
  
        // Reset state
        if (this.reader) {
          this.reader.cancel();
        }
        this.isStreaming = true;
  
        const response = await fetch('http://ec2-3-110-94-160.ap-south-1.compute.amazonaws.com/stream-response', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({ 
            question, 
            vector_db_slug: 'general', 
            message_history: this.messageHistory 
          })
        });
  
        this.reader = response.body.getReader();
        const decoder = new TextDecoder();
        this.currentBotBubble = document.createElement('div');
        this.currentBotBubble.className = 'bubble bot-bubble';
        this.$refs.output.appendChild(this.currentBotBubble);
  
        let botContent = ''; 
  
        while (this.isStreaming) {
          const { value, done } = await this.reader.read();
          if (done) {
            break;
          }
          const chunk = decoder.decode(value, { stream: true });
          botContent += chunk;
          this.currentBotBubble.innerHTML = marked.parse(botContent);
          this.$refs.chatContainer.scrollTop = this.$refs.chatContainer.scrollHeight;
        }
  
        // Add bot response to the message history
        this.messageHistory.push({ role: 'bot', content: botContent });
  
        document.getElementById('submitButton').style.display = 'inline';
        document.getElementById('stopButton').style.display = 'none';
      },
      handleStop() {
        if (this.reader) {
          this.reader.cancel(); 
        }
        this.isStreaming = false;
        document.getElementById('submitButton').style.display = 'inline'; 
        document.getElementById('stopButton').style.display = 'none'; 
      }
    },
    mounted() {
      // Optional: You can load any external scripts or setup initial states here
    }
  };
  </script>
  
  <style scoped>
  body {
    font-family: Arial, sans-serif;
    margin: 0;
    background-color: #f4f4f9;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    height: 100vh;
    overflow: hidden;
  }
  
  #chat-container-wrapper {
    display: flex;
    flex-direction: column;
    align-items: center;
    width: 100%;
    max-width: 600px;
  }
  
  h1 {
    color: #333;
    margin-top: 20px;
    text-align: center;
  }
  
  #chat-container {
    width: 100%;
    background: #ffffff;
    padding: 20px;
    border-radius: 10px;
    box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
    display: flex;
    flex-direction: column;
    overflow-y: auto;
    margin-bottom: 60px;
  }
  
  #inputForm {
    display: flex;
    width: 100%;
    background: #ffffff;
    padding: 10px 20px;
    box-shadow: 0 -2px 10px rgba(0, 0, 0, 0.1);
    border-top-left-radius: 10px;
    border-top-right-radius: 10px;
    box-sizing: border-box;
  }
  
  #textInput {
    flex: 1;
    padding: 10px;
    border-radius: 5px;
    border: 1px solid #ccc;
    margin-right: 10px;
  }
  
  #inputForm button {
    padding: 10px 20px;
    border-radius: 5px;
    border: none;
    cursor: pointer;
    margin-left: 5px;
  }
  
  #submitButton {
    background-color: #4CAF50;
    color: white;
  }
  
  #stopButton {
    background-color: #f44336;
    color: white;
    display: none;
  }
  
  #output {
    display: flex;
    flex-direction: column;
    margin-bottom: 10px;
  }
  
  .bubble {
    max-width: 80%;
    padding: 10px;
    margin: 5px 0;
    border-radius: 10px;
    word-wrap: break-word;
    position: relative;
  }
  
  .user-bubble {
    align-self: flex-start;
    background-color: #007bff;
    color: white;
    margin-left: auto; /* Align user bubbles to the right */
  }
  
  .bot-bubble {
    align-self: flex-end;
    background-color: #e9ecef;
    color: #333;
    margin-right: auto; /* Align bot bubbles to the left */
  }
  </style>
  