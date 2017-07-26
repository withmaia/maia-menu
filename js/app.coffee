React = require 'preact'
React.__spread = Object.assign
Redux = require 'redux'
update = require 'immutability-helper'
fetch$ = require 'kefir-fetch'
fetch$.setDefaultOptions
    base_url: 'http://192.168.0.182:8182'

window.onhashchange = ->
    Store.dispatch
        type: 'navigate'
        location: window.location.hash.slice(1)

treeFromLocation = (location, leaf, root={}, at={}) ->
    if typeof location == 'string'
        location = location.split '/'
        root = at
    next = location[0]
    if next.length > 0
        at = at[next] = {}
    if location.length > 1
        at = at.children = {}
        return treeFromLocation location.slice(1), leaf, root, at
    else
        Object.assign at, leaf
        return root

updateItemAtLocation = (item, location, update) ->
    item_update = {}
    item_update[item.key] = {$merge: update}
    Store.dispatch
        type: 'update'
        update:
            menu: treeFromLocation location, {children: item_update}

actions =
    toggle: (item) ->
        location = Store.getState().location
        doUpdate = (update) ->
            updateItemAtLocation item, location, update

        doUpdate {loading: true}
        fetch$ 'post', "/maia:hue/toggleState.json", {body: {args: [item.key]}}
            .onValue (response) ->
                console.log '[response]', response
                new_value = if response.on then 'on' else 'off'
                doUpdate {value: new_value, loading: false}
        # setTimeout ->
        #     new_value = if item.value == 'on' then 'off' else 'on'
        #     doUpdate {value: new_value, loading: false}
        # , Math.random() * 500

    reload: (item) ->
        location = Store.getState().location
        doUpdate = (update) ->
            updateItemAtLocation item, location, update

        doUpdate {loading: true}
        setTimeout ->
            new_value = item.value + (Math.random() - 0.5) * 5
            doUpdate {value: new_value, loading: false}
        , Math.random() * 500

    navigate: (item) ->
        window.location.hash = Store.getState().location + '/' + item.key

doAction = (item) -> (args...) ->
    console.log '[action item]', item
    actions[item.action](item, args...)

descend = (menu, location) ->
    console.log '[location]', location
    if typeof location == 'string'
        location = location.split '/'
    next = location[0]
    if next.length == 0
        child = menu
    else
        child = menu.children[next]
    if location.length > 1
        return descend child, location.slice(1)
    else
        return child

# ------------------------------------------------------------------------------

initial_state =
    location: window.location.hash.slice(1)
    menu:
        children:
            lights:
                key: 'lights'
                name: 'Lights'
                icon: 'lightbulb-o'
                action: 'navigate'
                children:
                    office_light:
                        key: 'office_light'
                        name: 'Office'
                        type: 'on_off'
                        value: 'on'
                        action: 'toggle'
                    living_room_light:
                        key: 'living_room_light'
                        name: 'Living Room'
                        type: 'on_off'
                        value: 'off'
                        action: 'toggle'
                    bedroom_lights:
                        key: 'bedroom_lights'
                        name: 'Bedroom'
                        type: 'on_off'
                        value: 'on'
                        action: 'toggle'
                    all_lights:
                        key: 'all_lights'
                        name: 'All'
                        type: 'on_off'
                        value: 'off'
                        action: 'toggle'
            climate:
                key: 'climate'
                name: 'Climate'
                icon: 'thermometer-half'
                action: 'navigate'
                children:
                    office:
                        key: 'office'
                        name: 'Office'
                        type: 'unit'
                        unit: 'º'
                        value: 70.2
                        action: 'reload'
                    living_room:
                        key: 'living_room'
                        name: 'Living room'
                        type: 'unit'
                        unit: 'º'
                        value: 70
                        action: 'reload'
            markets:
                key: 'markets'
                name: 'Markets'
                icon: 'bitcoin'
                action: 'navigate'
                children:
                    btc:
                        key: 'btc'
                        name: 'Bitcoin'
                        type: 'unit'
                        unit: '$'
                        value: 2544.5
                        action: 'reload'
                    eth:
                        key: 'eth'
                        name: 'Ethereum'
                        type: 'unit'
                        unit: '$'
                        value: 54.5
                        action: 'reload'
                    stocks:
                        key: 'stocks'
                        name: 'Stocks'
                        icon: 'usd'
                        action: 'navigate'
                        children:
                            tesla:
                                key: 'tesla'
                                name: 'TSLA'
                                type: 'unit'
                                unit: '$'
                                value: 555
                                action: 'reload'
                            apple:
                                key: 'apple'
                                name: 'AAPL'
                                type: 'unit'
                                unit: '$'
                                value: 666
                                action: 'reload'

# ------------------------------------------------------------------------------

combined_reducer = (state={}, action) ->
    switch action.type
        when 'navigate'
            return Object.assign {}, state, {location: action.location}
        when 'update'
            return update state, action.update
    return state

Store = Redux.createStore combined_reducer, initial_state

# ------------------------------------------------------------------------------

Spinner = -> <i className='fa fa-spin fa-circle-o-notch' />

Menu = ({menu}) ->
    console.log '[Menu]', menu
    <div className='menu'>
        {Object.entries(menu.children).map ([key, item]) ->
            <div key=key>
                {if item.type == 'on_off'
                    <OnOffValue item=item />
                else if item.type == 'unit'
                    <UnitValue item=item />
                else if item.children?
                    <MenuItem item=item />
                }
            </div>
        }
    </div>

MenuItem = ({item}) ->
    console.log '[MenuItem item]', item
    <div className="item" onClick={doAction(item)}>
        {if item.name?
            <span className='name'>
                {if item.icon?
                    <i className="fa fa-#{item.icon}" />
                }
                {item.name}
            </span>
        }
    </div>

OnOffValue = ({item}) ->
    <div className="item on-off #{item.value}" onClick={doAction(item)}>
        <span className='name'>{item.name}</span>
        {if item.loading
            <Spinner />
        }
    </div>

UnitValue = ({item}) ->
    <div className="item unit #{item.unit}" onClick={doAction(item)}>
        <span className='name'>{item.name}</span>
        <span className='value'>{item.value.toFixed(2)}{item.unit}</span>
        {if item.loading
            <Spinner />
        }
    </div>

class App extends React.Component
    constructor: ->
        @state = Store.getState()
        Store.subscribe =>
            @setState Store.getState()

    render: ->
        <div id='app-app'>
            <img id='logo' src='/images/maia-logo.png' />
            <div className='spacer' />
            <Menu menu={descend @state.menu, @state.location} />
        </div>

React.render <App />, document.getElementById 'app'
