pragma solidity ^0.4.4;

// https://github.com/Arachnid/solidity-stringutils
import "../lib/solidity-stringutils/strings.sol";

contract Meetup {
    /**
     * NOTES
     *
     * "organizer" is the person creating meetups.
     */

    /**
      * stringutils
      */
    using strings for *;

    /**
      * Events
      */
    event MeetupCreated(address organizer, bytes32 meetupHash);
    event MeetupDeleted(address organizer, bytes32 meetupHash);

    /**
      * meetup hashes that belong to an organzier
      */
    mapping (address => bytes32[]) public organizerMeetups;

    /**
      * meetups table
      * key is a hash, value is the struct.
      */
    mapping (bytes32 => MeetupEvent) meetups;

    /**
      * Contract owner
      */
    address owner;

    struct MeetupEvent {
        string title;
        string description;
        uint256 startTimestamp;
        uint256 endTimestamp;
    }

    function Meetup() {
        owner = msg.sender;
    }

    function changeOwner(address newOwner) {
        if (msg.sender == owner) {
            owner = newOwner;
        }
    }

    function createMeetup(
        string _title,
        string _description,
        uint256 _startTimestamp,
        uint256 _endTimestamp
    ) returns (bytes32) {
        address organizer = msg.sender;

        // Start time cannot be a date from the past
        if (_startTimestamp < block.timestamp) {
            throw;
        }

        // Start time cannot be afer end time
        if (_startTimestamp > _endTimestamp) {
            throw;
        }

        // Must have title
        if (bytes(_title).length == 0) {
            throw;
        }

        // Must have description
        if (bytes(_description).length == 0) {
            throw;
        }

        MeetupEvent memory meetup = MeetupEvent({
            title: _title,
            description: _description,
            startTimestamp: _startTimestamp,
            endTimestamp: _endTimestamp
        });

        string memory hashKey = addressToString(organizer).toSlice().concat(_title.toSlice());
        bytes32 meetupHash = sha3(hashKey);

        meetups[meetupHash] = meetup;
        organizerMeetups[organizer].push(meetupHash);

        MeetupCreated(organizer, meetupHash);

        return meetupHash;
    }

    function getMeetupHashes(address organizer) returns (bytes32[]) {
        return organizerMeetups[organizer];
    }

    function getMeetup(bytes32 meetupHash) returns (string, string) {
        MeetupEvent meetup = meetups[meetupHash];

        /*
         * check if meetup does not exist.
         * delete mapping items get initialized to their default.
         */
        if (sha3(meetup.title) == sha3("")) {
            throw;
        }

        string title = meetup.title;
        string description = meetup.description;

        return (title, description);
    }

    function deleteMeetup(bytes32 meetupHash) returns (bool) {
        address organizer = msg.sender;

        for (uint i = 0; i < organizerMeetups[organizer].length; i++) {
            if (organizerMeetups[organizer][i] == meetupHash) {
                removeFromOrganizerMeetupsArray(organizer, i);
                delete meetups[meetupHash];

                MeetupDeleted(organizer, meetupHash);

                return true;
            }
        }

        return false;
    }

    /**
      * UTILITY FUNCTIONS
      */

    // https://ethereum.stackexchange.com/a/8347/5093
    function addressToString(address x) returns (string) {
        bytes memory b = new bytes(20);
        for (uint i = 0; i < 20; i++) {
            b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));
        }
        return string(b);
    }

    // https://ethereum.stackexchange.com/a/1528/5093
    function removeFromOrganizerMeetupsArray(address organizer, uint index) returns (bytes32[]) {
        bytes32[] storage array = organizerMeetups[organizer];
        if (index >= array.length) return;

        for (uint i = index; i < array.length - 1; i++){
            array[i] = array[i + 1];
        }

        delete array[array.length - 1];
        array.length = array.length - 1;
        return array;
    }
}