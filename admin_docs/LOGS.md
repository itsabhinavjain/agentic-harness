## NanoClaw 
Requires docker which can be an issue with performance (within docker)
You might want to run it directly on the host 

```
git clone https://github.com/qwibitai/NanoClaw.git
cd NanoClaw
claude
```
```
/setup
```
**Status** : 
- Haven't been able to run this yet because of docker within docker issues
- Might have to run it directly on the host since it anyways uses docker for containerisation

## NanoBot 
Binary 
```
uv tool install nanobot-ai
nanobot onboard
```

### Provider 
Configuration 
```
Agents :-
"model": "gemini-2.5-flash"

Providers :- 
"gemini"
```

```
nanobot agent -m "Hello!"
nanobot agent 
```

### Channels  
Configuration
```
```

Running the gateway
```
nonabot gateway
```

**Status** : 
- Was not able to run the gateway, probably because of docker etc  
- Might have to run it directly on the host since it anyways uses docker for containerisation