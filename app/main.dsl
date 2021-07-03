/**
Initialize the variables. Named Entities are stored as data arrays which is why we are initializing the variables as data arrays. 
*/

context 
{
    input phone: string;
    input name: string = "";

    software: {[x:string]:string;}[]?=null;
    invoices: {[x:string]:string;}[]?=null;
    lead_source: {[x:string]:string;}[]?=null;
    calltime: {[x:string]:string;}[]?=null;
    callday: {[x:string]:string;}[]?=null;
    callback: {[x:string]:string;}[]?=null;
    visitedNodeTime: boolean = false;
    visitedNodeQuestion1: boolean = false;
}

/**
Perfect world conversation flow begins 
*/

start node root
{
    do
    {
        #preparePhrase("greeting", {name:$name}); 
        #connectSafe($phone);
        // Wait until 5 seconds passes or speech is detected.
        #waitForSpeech(5000);
        #say("greeting", {name: $name});
        wait*;
    }
    transitions
    {
        question_1: goto question_1 on #messageHasIntent("yes");
        call_back: goto call_back on #messageHasIntent("no");
    }
}


node question_1
{
    do 
    {

        if ($visitedNodeQuestion1==false) #sayText("Great! I will book you in for a discovery call with an account executive but first, I'll have to ask you a couple of questions . Question 1 - are you using any other software at the moment that solve for invoicing?"); 
        else #sayText("Going back to the question 1 - are you using any other software at the moment that solve for invoicing?"); 
        set $visitedNodeQuestion1=true;
        wait *;
    wait*;
    }
    transitions
    {
        question_1_a: goto question_1_a on #messageHasIntent("yes");
        question_2: goto question_2 on #messageHasIntent("no");
    }
}

node question_1_a
{
    do 
    {
        #sayText("Great and what software are you using?");
        wait *;
    }
    transitions 
    {
       question_2: goto question_2 on #messageHasData("software");
    }
    onexit
    {
        question_2: do {
        set $software = #messageGetData("software");
       }
    }
}

node question_2
{
    do 
    {
        #sayText("Thank you for that. Question 2 - how many invoices per month do you generally issue?");
        wait *;
    }
    transitions 
    {
       question_3: goto question_3 on #messageHasData("numberword");
    }
    onexit
    {
        question_3: do {
        set $invoices = #messageGetData("numberword");
       }
    }
}

node question_3
{
    do 
    {
        #sayText("Thank you. And final question - how did you find out about us?");
        wait *;
    }
    transitions 
    {
       time: goto time on #messageHasData("channel");
    }
    onexit
    {
        time: do {
        set $lead_source = #messageGetData("channel");
       }
    }
}


node time
{
    do 
    {
        if ($visitedNodeTime == false) #sayText("Great, thank you for your replies. Now, let's find a time to meet. When are you available for a 30 minute call this week?"); 
        else #sayText("Let's try this again. What time can you meet with the A. E. this week?"); 
        set $visitedNodeTime=true;
        wait *;
    }
    transitions 
    {
       time_confirm: goto time_confirm on #messageHasData("callday");
    }
    onexit
    {
        time_confirm: do 
    {
        set $callday = #messageGetData("callday");
        set $calltime = #messageGetData("numberword");

    }
    }
}

node time_confirm
{
    do
    {
        #sayText("Perfect. Let's confirm, you can take a call on ");
        var callday = #messageGetData("callday");
        for (var item in callday)
            {
                #sayText(item.value ?? "");
            }
        #sayText(" at ");
        var calltime = #messageGetData("numberword");
        for (var item in calltime)
            {
                #sayText(item.value ?? "");
            }

        #sayText(" is that right?");
        wait *;
    }
     transitions 
    {
        correct: goto success on #messageHasIntent("yes");
        incorrect: goto time on #messageHasIntent("no");
    }
}

node success
{
    do 
    {
        #sayText("Perfect. You will have an invite later today. Thank you so much! We'll speak soon! Bye!");
        #disconnect();
        exit;
    }
}

/**
Perfect world conversation flow ends

Can't talk now flow begins
*/


node call_back
{
    do 
    {
        #sayText("No worries, when may we call you back?");
        wait *;
    }
    transitions 
    {
       callback_confirm: goto callback_confirm on #messageHasData("callback");
    }
    onexit
    {
        callback_confirm: do 
        {
        set $callback = #messageGetData("callback");
        }
    }
}

node callback_confirm
{ 
    do 
    { 
        #sayText("Perfect. we'll call you back");
        var callbackday = #messageGetData("callback");
        for (var item in callbackday)
            {
                #sayText(item.value ?? "");
            }
        #sayText(". Thanks for your time. Bye! ");
        exit;
    }
}


/**
Can't talk now flow ends

Digressions begin
*/

digression can_help
{
     conditions {on #messageHasIntent("can_help");}
    do
    {
        #sayText("How can I help?");
        wait *;
    }
}

digression connect_me 
{
    conditions {on #messageHasIntent("connect_me");}
    do 
    {
        #sayText("Certainly. Please hold, I will now transfer you. Good bye!");
        #forward("79231017918");
    }
}

digression who_call 
{
    conditions {on #messageHasIntent("who_call");}
    do 
    {
        #sayText("This is Dasha with Acme Software. You reached out to us a few minutes ago on our website.");
        return;
    }
}

digression what_do 
{
    conditions {on #messageHasIntent("what_do");}
    do 
    {
        #sayText("Acme Software provides invoicing software as a service for SMB. ");
        return;
    }
}

digression how_do 
{
    conditions {on #messageHasIntent("how_do");}
    do 
    {
        #sayText("I'm well, thank you!");
        return;
    }
}

digression transfer_me 
{
    conditions {on #messageHasIntent("transfer_me");}
    do 
    {
        #sayText("Certainly. Please hold, I will transfer you to an account executive right away. Good bye!");
        #forward("79231017918");
    }
}

digression bye 
{
    conditions { on #messageHasIntent("bye"); }
    do 
    {
        #sayText("Thank you for your time. Have a great day. Bye!");
        #disconnect();
        exit;
    }
}

/**
Digressions end
*/