const tc = require('truffle-contract')
const detectNetwork = require('web3-detect-network')

const {getJson, ipfsUrl} = require('../services/ipfs')
const Meetup = require('../../build/contracts/Meetup.json')
const {DEFAULT_MEETUP_IMAGE} = require('../constants/defaults')
const { getPosts } = require('./query')

let contract = null;

class Contract {
  constructor() {
    this.instance = null
    this.account = null
  }

  setContractInstance(instance) {
    this.instance = instance

    this.instance.allEvents()
    .watch((error, log) => {
      if (error) {
        console.error(error)
        return false
      }

      console.log('Event', log)
    })
  }

  setAccount (account) {
    this.account = account
  }

  createMeetup({ ipfsHash }) {
    if (!this.instance) {
      return Promise.reject()
    }

    return this.instance.createMeetup(ipfsHash, {from: this.account})
  }

  editMeetup({ id, ipfsHash }) {
    if (!this.instance) {
      return Promise.reject()
    }

    return this.instance.editMeetup(id, ipfsHash, {from: this.account})
  }

  async getAllMeetups(organizer) {
    // attempt to get posts from db first
    try {
      const posts = await getPosts()
      return posts
    } catch (error) {
      console.error(error)
    }

    if (!this.instance) {
      return Promise.reject()
    }

    return new Promise(async (resolve, reject) => {
      let meetups = []
      // const lastId = await this.instance.seqId.call()
      const lastId = 99

      for (let i = 1; i < lastId; i++) {
        const meetup = await this.getMeetupById(i)

        if (!parseInt(meetup.organizer, 16)) {
          break
        } else {
          if (meetup.title) {
            meetups.push(meetup)
          }
        }
      }

      meetups = meetups.filter(x => !x.deleted)

      resolve(meetups.reverse())
    })
  }

  async getMeetupById(id) {
    if (!this.instance) {
      return Promise.reject()
    }

    const [_id, organizer, ipfsHash] = await this.instance.getMeetup(id)

    const json = await getJson(ipfsHash)
    json.id = _id.toNumber()
    json.tags = json.tags || []
    json.title = json.title || ''
    json.description = json.description || ''
    json.imageUrl = ipfsUrl(json.image || DEFAULT_MEETUP_IMAGE);
    json.organizer = organizer
    return json
  }

  deleteMeetupById(id) {
    if (!this.instance) {
      return Promise.reject()
    }

    return new Promise((resolve, reject) => {
      this.instance.deleteMeetupByHash(
      id,
      (error, result) => {
        if (error) return reject(error)

        resolve()
      })
    })
  }
}

function getProvider() {
  if (window.web3) {
    return window.web3.currentProvider
  }

  const providerUrl = 'https://rinkeby.infura.io:443'
  const provider = new window.Web3.providers.HttpProvider(providerUrl)

  return provider
}

async function init() {
  contract = new Contract()

  let instance = tc(Meetup)
  const provider = getProvider()
  const {type} = await detectNetwork(provider)

  if (type !== 'rinkeby') {
    alert('Please connect to Rinkeby network')
  }

  instance.setProvider(provider)
  instance = await instance.deployed()

  contract.setContractInstance(instance)

  if (window.web3) {
    contract.setAccount(web3.eth.defaultAccount || web3.eth.accounts[0])
  }
}

function getInstance() {
  return contract
}

module.exports = {
  init,
  getInstance
}
