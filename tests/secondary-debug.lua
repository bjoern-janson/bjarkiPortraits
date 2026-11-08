-- Commands must provide a compact read-only diagnostic of last election.
local messages={}
local BP={Runtime={db={secondaryPortrait=true},PARTY_UNITS={}}}
local R=BP.Runtime
R.Print=function(s) messages[#messages+1]=s end
R.hosts={target={_secondaryMode='hidden',_secondaryElectionReason='npc-native-slot-unreadable',
  _playerReadable=true,_isPlayer=false,_hostileUnit=true,_hostileCount=0,
  _exactHarmfulAllowed=true,_containerWriteFailures=0}}
SlashCmdList={}
assert(loadfile('Commands.lua'))('bjarkiPortraits',BP)
SlashCmdList.BJARKIPORTRAITS('secondary debug target')
assert(#messages==2, 'compact summary should print exactly two lines')
assert(messages[1]:find('reason=npc%-native%-slot%-unreadable'),'reason visible')
assert(messages[2]:find('player=false',1,true),'NPC identity visible')
assert(messages[2]:find('hCount=0',1,true),'hostile list count visible')
assert(R.db.secondaryPortrait==true,'read-only command must not toggle anything')
print('secondary compact diagnostics: 4 assertions passed')
